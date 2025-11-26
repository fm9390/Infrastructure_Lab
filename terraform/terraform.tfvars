pm_api_url          = "https://192.168.178.198:8006"
pm_token_id         = "root@pam!terraform2=3bc9c3cb-4c14-43a0-880e-f198d9bd46e5"
pm_node             = "pve" 
bridge              = "vmbr0"
template_name       = "ubuntu-24.04-ci-template"
cloudinit_storage   = "local"
disk_storage        = "local-lvm"
ssh_public_key      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKo7hYnzwAOAFi2nSKczf/0vT1P5K4prG2UF93dxn51R fanny.mayer7@gmail.com"
pm_ssh_host         = "192.168.178.198"

vms = {
  Proxy_VM = {
    cores     = 1
    memory_mb = 512
    disk_gb   = 20
    hostname  = "proxy"
    ip        = "192.168.178.201"  
    gw       = "192.168.178.1"
  }

  Gitlab_VM = {
    cores     = 2
    memory_mb = 6144
    # 4096
    disk_gb   = 100
    hostname  = "gitlab"
    ip        = "192.168.178.202"
    gw       = "192.168.178.1"
  }

   WP_DEV_VM = {
    cores     = 1
    memory_mb = 2048
    disk_gb   = 30
    hostname  = "wp-dev"
    ip        = "192.168.178.203"
    gw        = "192.168.178.1"
  }

  WP_PROD_VM = {
    cores     = 2
    memory_mb = 1024
    disk_gb   = 50
    hostname  = "wp-prod"
    ip        = "192.168.178.204"
    gw        = "192.168.178.1"
  }
}
