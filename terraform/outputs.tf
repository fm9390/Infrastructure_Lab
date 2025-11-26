# outputs.tf

# VM-IDs (numerisch)
output "vm_ids" {
  value = { for k, r in proxmox_virtual_environment_vm.vm : k => r.vm_id }
}

# Hostname -> statische IP (aus deinen Variablen)
output "hosts_static_ips" {
  value = { for k, cfg in var.vms : k => cfg.ip }
}

# (Optional) Von Proxmox/Guest-Agent gemeldete IPv4-Adressen
# bpg liefert ipv4_addresses als Liste (pro Netzwerkkarte)
output "hosts_agent_ips" {
  value = {
    for k, r in proxmox_virtual_environment_vm.vm :
    k => (length(r.ipv4_addresses) > 0 ? r.ipv4_addresses[0] : null)
  }
}
