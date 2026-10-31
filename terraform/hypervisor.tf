resource "proxmox_virtual_environment_file" "hypervisor_user_data" {
  node_name    = "knas9"
  datastore_id = "local"
  content_type = "snippets"

  source_raw {
    file_name = "hypervisor-user-data.yaml"
    data = "#cloud-config\n${yamlencode({
      hostname     = "hypervisor"
      disable_root = false

      users = [
        {
          name   = "alisher"
          groups = ["wheel"]
          shell  = "/run/current-system/sw/bin/bash"
          sudo   = "ALL=(ALL) NOPASSWD:ALL"

          ssh_authorized_keys = [
            trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))
          ]
        },
        {
          name = "root"
          ssh_authorized_keys = [
            trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))
          ]
        },
      ]
    })}"
  }
}

resource "proxmox_virtual_environment_vm" "hypervisor" {
  name       = "hypervisor"
  node_name  = "knas9"
  boot_order = ["virtio0"]

  tags = ["managed_terraform", "os_nixos"]

  cpu {
    cores = 20
    type  = "host"
  }

  memory {
    dedicated = 32768
  }

  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_download_file.nixos.id
    interface    = "virtio0"
    file_format  = "raw"
    size         = 16
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.hypervisor_user_data.id

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  operating_system {
    type = "l26"
  }

  serial_device {}
}

output "hypervisor" {
  value = {
    vm_id          = proxmox_virtual_environment_vm.hypervisor.vm_id
    ipv4_addresses = proxmox_virtual_environment_vm.hypervisor.ipv4_addresses
  }
}
