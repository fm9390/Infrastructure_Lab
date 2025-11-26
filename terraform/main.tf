terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.84.1"
    }
  }
}

provider "proxmox" {
  endpoint      = var.pm_api_url
  api_token     = var.pm_token_id
  insecure      = true

  ssh {
    agent = false
    username = "root"
    private_key = file("/Users/fannymayer/.ssh/id_ed25519")
  }
}

############################
# SSH-Key laden
############################
data "local_file" "ssh_public_key" {
  # Passe den Pfad an dein System an
  filename = "/Users/fannymayer/.ssh/id_ed25519.pub"
}


############################
# Cloud-Init Snippet erstellen (User, Agent, SSH)
############################
resource "proxmox_virtual_environment_file" "cloudinit_snippet" {
  content_type = "snippets"
  datastore_id = var.cloudinit_storage     # bei dir: "local"
  node_name    = var.pm_node               # z.B. "pve"

  source_raw {
    file_name = "ubuntu-24.04-cloudinit.yaml"
    data = <<-EOF
    #cloud-config
    timezone: Europe/Berlin
    users:
      - name: fanny
        groups: [sudo]
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
          - ${trimspace(data.local_file.ssh_public_key.content)}
    package_update: true
    package_upgrade: true
    packages:
      - qemu-guest-agent
      - openssh-server
      - curl
      - net-tools
    runcmd:
      - systemctl enable --now qemu-guest-agent
      - systemctl enable --now ssh
      - systemctl restart ssh
      - echo "cloud-init completed" > /tmp/cloud-init.log
    EOF
  }
}

############################
# Ubuntu 24.04 Cloud-Image herunterladen
############################
resource "proxmox_virtual_environment_download_file" "ubuntu_qcow2" {
  node_name    = var.pm_node
  datastore_id = var.cloudinit_storage     # Datei landet z.B. in "local"
  content_type = "iso"                     # Provider akzeptiert "iso" für Downloads
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  file_name    = "ubuntu-24.04-noble.img"
}

############################
# Template-VM deklarativ erstellen (template = true)
############################
resource "proxmox_virtual_environment_vm" "ubuntu_template" {
  name      = var.template_name            # z.B. "ubuntu-24.04-ci-template"
  node_name = var.pm_node                  # z.B. "pve"
  vm_id     = 9001
  template  = true

  operating_system { type = "l26" }
  agent { enabled = true }

  cpu { cores = 2  }
  memory {  dedicated = 2048 }

  # Systemdisk aus dem heruntergeladenen QCOW2 importieren → auf dein SSD/LVM-Storage
  disk {
    datastore_id = var.disk_storage        # "local-lvm"
    interface    = "scsi0"
    file_id  = proxmox_virtual_environment_download_file.ubuntu_qcow2.id
    size         = 20
    discard      = "on"
  }

  network_device {
    bridge = var.bridge                    # z.B. "vmbr0"
    model  = "virtio"
  }

  initialization {
    # Cloud-Init Drive/Metadata auf dem "Snippet/ISO-Storage"
    datastore_id      = var.disk_storage  
    user_data_file_id = proxmox_virtual_environment_file.cloudinit_snippet.id

    ip_config {
      ipv4 { address = "dhcp" }                 # Template selbst darf DHCP haben
    }
  }
}

############################
# VMs aus Template klonen (deine Map var.vms)
############################
resource "proxmox_virtual_environment_vm" "vm" {
  depends_on = [proxmox_virtual_environment_vm.ubuntu_template]
  for_each   = var.vms

  node_name = var.pm_node
  name      = each.value.hostname
  started   = true

  clone {
    vm_id        = 9001
    full         = true
    datastore_id = var.disk_storage
  }

  cpu {
    cores = each.value.cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = each.value.memory_mb
  }

  agent { enabled = true }

  disk {
    datastore_id = var.disk_storage
    interface    = "scsi0"
    size         = each.value.disk_gb
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  initialization {
    datastore_id      = var.disk_storage
    user_data_file_id = proxmox_virtual_environment_file.cloudinit_snippet.id

    dns {
      servers = [
        "192.168.178.1", # FritzBox
        "1.1.1.1",       # optional: Cloudflare als Fallback
      ]
    }


    # statische IPs aus deiner Map
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = each.value.gw
      }
    }
  }
}


