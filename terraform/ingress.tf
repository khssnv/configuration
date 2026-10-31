resource "proxmox_virtual_environment_file" "ingress_user_data" {
  node_name    = "knas9"
  datastore_id = "local"
  content_type = "snippets"

  source_raw {
    file_name = "ingress-user-data.yaml"
    data = "#cloud-config\n${yamlencode({
      hostname     = "ingress"
      disable_root = false

      users = [
        {
          name   = "alisher"
          groups = ["wheel"]
          shell  = "/run/current-system/sw/bin/bash"
          # NixOS resets sudoers on reboot or rebuild, disabling this rule.
          # Define persistent sudo rules in Nix.
          sudo = "ALL=(ALL) NOPASSWD:ALL"

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
