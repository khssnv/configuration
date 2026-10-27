# ingress

Homelab ingress via a public VPS and VPN, with optional TLS termination.

## Apply configuration

```sh
nixos-rebuild switch --flake .#ingress --target-host root@"$INGRESS_IP"
```

## Bootstrap

Create the VM with [Terraform](../../terraform/README.md).

```sh
INGRESS_IP="<vm-ip>" # get the IP from Terraform output.

ssh root@"$INGRESS_IP" 'nixos-generate-config --show-hardware-config' > hardware-configuration.nix
nixos-rebuild switch --flake .#ingress --target-host root@"$INGRESS_IP"
ssh alisher@"$INGRESS_IP" 'sudo reboot'
```

## WireGuard

- [VPS](../2.vpsza500/wireguard.nix): `10.201.0.1`, endpoint `2.vpsza500.khassanov.xyz:51820/udp`.
- [Ingress](wireguard.nix): `10.201.0.2`, initiates the tunnel with a 25-second keepalive.
- Interface: `wg0`; tunnel subnet: `10.201.0.0/30`. Only peer tunnel addresses are routed through VPN.

Private keys are generated on each host at `/var/lib/wireguard/private.key`.
Public keys are configured in the peer's module; update them if a private key changes.
