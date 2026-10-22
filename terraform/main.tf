terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.114.0"
    }
  }
}

provider "proxmox" {
  ssh {
    agent    = true
    username = "root"

    node {
      name    = "knas9"
      address = "knas9.lan"
    }
  }
}

data "proxmox_datastores" "knas9" {
  node_name = "knas9"
}

output "knas9_datastores" {
  value = data.proxmox_datastores.knas9.datastores
}
