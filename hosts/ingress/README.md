# ingress

Homelab ingress via a public VPS and VPN, with optional TLS termination.

## Bootstrap

Create the VM with [Terraform](../../terraform/README.md).

```sh
INGRESS_IP="<vm-ip>" # get the IP from Terraform output.

ssh root@"$INGRESS_IP" 'nixos-generate-config --show-hardware-config' > hardware-configuration.nix
nixos-rebuild switch --flake .#ingress --target-host root@"$INGRESS_IP"
ssh alisher@"$INGRESS_IP" 'sudo reboot'
```

## Apply configuration

```sh
nixos-rebuild switch --flake .#ingress --target-host root@"$INGRESS_IP"
```
