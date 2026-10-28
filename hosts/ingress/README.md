# ingress

Homelab ingress via a public VPS and WireGuard, with optional TLS termination.

Start with [configuration.nix](configuration.nix); public listeners and TLS are
configured in [nginx.nix](nginx.nix).

See [DNS setup](DNS.md) to publish a service and [Security](SECURITY.md) for
trust boundaries and required isolation.

Run deployment commands from `hosts/ingress/` with Nix, flakes, `nixos-rebuild`,
and SSH access available. Set the VM address:

```sh
INGRESS_IP="<vm-ip>"
```

## Bootstrap

Create the VM with [Terraform](../../terraform/README.md), then generate its
hardware configuration:

```sh
ssh root@"$INGRESS_IP" 'nixos-generate-config --show-hardware-config' > hardware-configuration.nix
```

Review the generated file, [apply the configuration](#apply-configuration),
then reboot with `ssh root@"$INGRESS_IP" 'reboot'`.

## Apply configuration

```sh
nixos-rebuild switch --flake .#ingress --target-host root@"$INGRESS_IP"
```

Check that Nginx is active and the gateway is reachable through WireGuard.
Verify public access and certificate issuance using [DNS checks](DNS.md#verify).

## WireGuard

Peer addresses, routes, endpoint, and keepalive are defined in the
[gateway](../2.vpsza500/wireguard.nix) and [ingress](wireguard.nix) modules.
Only peer tunnel addresses are routed through the VPN.

Each host generates `/var/lib/wireguard/private.key`. If a key changes, update
the public key in the peer's module.

## TODO

- [DNS.md](./DNS.md) and [SECURITY.md](./SECURITY.md) are AI-generated. Rework
  after publishing the first service.
