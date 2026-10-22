resource "proxmox_virtual_environment_vm" "ingress" {
  name       = "ingress"
  node_name  = "knas9"
  boot_order = ["virtio0"]

  tags = ["managed_terraform", "os_nixos"]

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_download_file.nixos.id
    interface    = "virtio0"
    file_format  = "raw"
    size         = 8
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.ingress_user_data.id

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  agent {
    enabled = true

    wait_for_ip {
      ipv4 = true
    }
  }

  operating_system {
    type = "l26"
  }

  serial_device {}
}

output "ingress" {
  value = {
    vm_id          = proxmox_virtual_environment_vm.ingress.vm_id
    ipv4_addresses = proxmox_virtual_environment_vm.ingress.ipv4_addresses
  }
}
