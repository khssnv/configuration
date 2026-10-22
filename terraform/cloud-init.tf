resource "proxmox_virtual_environment_file" "ingress_user_data" {
  node_name    = "knas9"
  datastore_id = "local"
  content_type = "snippets"

  source_raw {
    file_name = "ingress-user-data.yaml"
    data = "#cloud-config\n${yamlencode({
      hostname = "ingress"

      users = [{
        name   = "alisher"
        groups = ["wheel"]
        shell  = "/run/current-system/sw/bin/bash"
        # NixOS resets sudoers on reboot or rebuild, disabling this rule.
        # Define persistent sudo rules in Nix.
        sudo = "ALL=(ALL) NOPASSWD:ALL"

        ssh_authorized_keys = [
          trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))
        ]
      }]
    })}"
  }
}
