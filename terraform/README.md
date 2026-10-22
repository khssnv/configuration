# terraform

- VM: `ingress`, node `knas9`; 4 CPU, 4096 MiB RAM, 8 GiB disk.
- Storage: `local` with `import` and `snippets` enabled; `local-lvm` for disks. Configure on Proxmox VE before applying.
- Network: `vmbr0`, DHCPv4.
- SSH: `root@knas9.lan`, key loaded in `ssh-agent`.
- Guest public key: `~/.ssh/id_ed25519.pub`.
- Environment: copy `.env.example` to `.env`; set API endpoint and token.
- State: local `terraform.tfstate`; ignored by Git. Back up separately.
- Bootstrap: user, SSH keys and sudo via `cloud-init.tf`; define sudo rules in Nix before rebooting or rebuilding. SSH survives reboot; `NOPASSWD` does not.

Run from `terraform/`:

```sh
source .env
terraform init
terraform validate
terraform plan
terraform apply
```
