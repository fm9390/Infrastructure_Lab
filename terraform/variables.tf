variable "pm_api_url"        { type = string }
variable "pm_token_id"       { type = string }   # z.B. "terraform@pve!tf"
variable "pm_node"           { type = string }   # z.B. "pve"
variable "bridge"            { type = string }   # z.B. "vmbr0"
variable "cloudinit_storage" { type = string }   # z.B. "local"
variable "disk_storage"      { type = string }   # z.B. "local-lvm"
variable "ssh_public_key"    { type = string }   # dein ~/.ssh/id_rsa.pub Inhalt
variable "pm_ssh_host"       { type = string }   # IP oder DNS-Name des Proxmox-Hosts für SSH (z.B. 192.168.178.198)
  
  
# Definiere deine VMs als Map
variable "vms" {
  type = map(object({
    cores     = number
    memory_mb = number
    disk_gb   = number
    hostname  = string
    ip        = string # "dhcp" oder "192.168.10.50/24"
    gw        = string # leer bei DHCP, sonst z.B. "192.168.10.1"
  }))
}

variable "template_name" {
  type        = string
  description = "Der Name des Proxmox-Templates, das geklont wird."
  default     = "ubuntu-24-04-ci-template"
}

