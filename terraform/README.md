# terraform

- VM: `ingress`, node `knas9`; 4 vCPU, 4096 MiB RAM, 8 GiB disk.
- VM: `hypervisor`, node `knas9`; 20 vCPU, 32768 MiB RAM without ballooning, 16 GiB disk.
- Storage: `local` with `import` and `snippets` enabled; `local-lvm` for disks. Configure on Proxmox VE before applying.
- Network: `vmbr0`, DHCPv4.
- SSH: `root@knas9.lan`, key loaded in `ssh-agent`.
- Guest public key: `~/.ssh/id_ed25519.pub`.
- Environment: copy `.env.example` to `.env`; set API endpoint and token.
- State: local `terraform.tfstate`; ignored by Git. Back up separately.
- Bootstrap: each VM file contains its cloud-init resource, providing SSH keys for `root` and `alisher`, plus passwordless sudo for `alisher`.

Run from `terraform/`.

1. Create and edit the local API configuration.

    ```console
    cp .env.example .env
    ${EDITOR:-vi} .env
    ```

1. Load API settings and install Terraform providers.

    ```console
    source .env
    terraform init
    ```

1. Create the VMs and cloud-init files, confirming with `yes` when prompted.

    ```console
    terraform apply
    ```

1. Obtain the non-loopback IPv4 addresses reported by the guest agent for `ingress`.

    ```console
    terraform output ingress
    ```

    To recreate an existing VM and delete its current data, use this instead of the normal apply command.

    ```console
    terraform apply -replace=proxmox_virtual_environment_vm.ingress
    ```

1. Continue with NixOS deployment in [../hosts/ingress/README.md](../hosts/ingress/README.md).
