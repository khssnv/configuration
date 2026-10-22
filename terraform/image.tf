resource "proxmox_download_file" "nixos" {
  node_name    = "knas9"
  datastore_id = "local"
  content_type = "import"
  file_name    = "nixos-26.05-349126072.raw"

  url = "https://hydra.nixos.org/build/349126072/download/1/vzdump-qemu-nixos-26.05pre-git.img"

  checksum_algorithm = "sha256"
  checksum           = "630148e3e7a9d20c7e151ba4c130625ef714ee4e6951359f5325338e4b7ad147"
  upload_timeout     = 3600
}
