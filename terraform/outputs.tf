output "hypervisor" {
  description = "Hypervisor VM ID and IPv4 addresses reported by the guest agent."

  value = {
    vm_id          = proxmox_virtual_environment_vm.hypervisor.vm_id
    ipv4_addresses = proxmox_virtual_environment_vm.hypervisor.ipv4_addresses
  }
}

output "ingress" {
  description = "Ingress VM ID and IPv4 addresses reported by the guest agent."

  value = {
    vm_id          = proxmox_virtual_environment_vm.ingress.vm_id
    ipv4_addresses = proxmox_virtual_environment_vm.ingress.ipv4_addresses
  }
}

output "knas9_datastores" {
  description = "Datastores on the knas9 Proxmox VE node."

  value = data.proxmox_datastores.knas9.datastores
}
