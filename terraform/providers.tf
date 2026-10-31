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
