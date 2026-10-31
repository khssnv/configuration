# ingress

Homelab ingress via a public VPS and WireGuard, with optional TLS termination.

```sh
INGRESS_IP="<vm-lan-ip>"
```

## Bootstrap or restore

1. Before replacing the VM, back up [WireGuard](#backup) and [ACME](DNS.md#save).
   Keep backups outside ingress and the gateway. For encrypted backups, store
   the decryption identity separately. Preserve configuration changes, DNS/CAA records,
   and [Terraform state](../../terraform/README.md) separately. Test recovery
   before deleting the source.
1. Create the VM with [Terraform](../../terraform/README.md); obtain its address
   with `terraform output ingress` from `terraform/`.
1. Verify the new SSH host key through the Proxmox console before replacing
   any old known-host entry. Keep console access until deployment is verified.
1. Generate hardware configuration:

   ```sh
   ssh root@"$INGRESS_IP" 'nixos-generate-config --show-hardware-config' > hardware-configuration.nix
   ```

   Review the filesystem UUID and boot disk. Check that the SSH interface and
   authorized key in [configuration.nix](configuration.nix) still match the VM.
1. Before deploying, restore [WireGuard](#restore) and [ACME](DNS.md#restore).
   Without backups, use [Lost WireGuard key](#lost-key) and
   [Lost ACME state](#lost-acme-state).
1. [Deploy](#apply-configuration), complete key/account replacement if needed,
   and [verify](#verification). Reboot and repeat verification, including a new
   SSH session:

   ```sh
   ssh root@"$INGRESS_IP" 'reboot'
   ```

## Apply configuration

```sh
nixos-rebuild switch --flake .#ingress --target-host root@"$INGRESS_IP"
```

## WireGuard

See [ingress](wireguard.nix) and [gateway](../2.vpsza500/wireguard.nix) modules.

### Backup

Back up after setup and key replacement. Use a new archive filename each time.
Store the unencrypted archive on a trusted machine with protected storage and
restricted file access, outside repositories and shared folders.

```sh
WG_BACKUP="/path/to/ingress-wireguard.tar.gz"
umask 077
ssh root@"$INGRESS_IP" \
  'tar --numeric-owner -C /var/lib -czf - wireguard/private.key' \
  > "$WG_BACKUP"
```

Check the exit status; failed commands can leave incomplete archives.

### Restore

Restore a trusted backup before first deployment. If a key already exists,
use it with [Lost key](#lost-key), or stop WireGuard and preserve it separately
before restoring. Do not overwrite a running interface's key.

```sh
WG_BACKUP="/path/to/ingress-wireguard.tar.gz"
ssh root@"$INGRESS_IP" \
  'install -d -m 700 -o root -g root /var/lib/wireguard && test ! -e /var/lib/wireguard/private.key' \
  && ssh root@"$INGRESS_IP" 'tar --numeric-owner -C /var/lib -xzf -' < "$WG_BACKUP"
```

Proceed only if successful:

```sh
ssh root@"$INGRESS_IP" \
  'chown root:root /var/lib/wireguard/private.key && chmod 600 /var/lib/wireguard/private.key'
```

Deploy; no gateway update is needed if the restored key matches its peer entry.
If restoring onto an already configured VM, reboot to load the restored key.

### Lost key

1. Deploy ingress; a missing key is generated automatically. Reuse an already
   generated replacement key. If ACME state is also lost, use the temporary
   configuration below.
1. Obtain the public key:

   ```sh
   ssh root@"$INGRESS_IP" 'wg show wg0 public-key'
   ```

1. Replace `peers[].publicKey` in [the gateway module](../2.vpsza500/wireguard.nix)
   and [deploy the gateway](../2.vpsza500/README.md#apply-configuration-remotely)
   from `hosts/2.vpsza500/`.
1. If the gateway key was also lost, obtain its new public key the same way,
   update [ingress's peer entry](wireguard.nix), and redeploy ingress.
1. [Verify the tunnel](#verification) and save a new backup.

## Lost ACME state

Certificates alone do not preserve the account required by CAA `accounturi`.

1. Temporarily set `enableACME = false` and `forceSSL = false` in
   [nginx.nix](nginx.nix), deploy, and recover WireGuard first.
1. Restore both settings to `true` and deploy to register a new ACME account.
   Issuance can fail while CAA still names the old account.
1. Follow [DNS setup](DNS.md#publish-or-restore-a-service) to obtain the new
   account URI and update CAA. Wait for DNS caches; keep the account restriction.
1. Retry issuance on ingress:

   ```sh
   ssh root@"$INGRESS_IP" 'systemctl start acme-order-renew-ingress.khassanov.xyz.service'
   ```

1. [Verify](DNS.md#verify) and [back up the new ACME state](DNS.md#save).

## Verification

```sh
ssh root@"$INGRESS_IP" 'systemctl --failed'
ssh root@"$INGRESS_IP" 'systemctl is-active wireguard-wg0.service nginx.service'
ssh root@"$INGRESS_IP" 'ping -c 3 10.201.0.1'
ssh root@"$INGRESS_IP" 'wg show wg0 latest-handshakes; wg show wg0 transfer'
```

Expect a recent nonzero handshake after traffic. Otherwise check peer keys,
endpoint DNS, and gateway UDP 51820 reachability.

From the administrative machine used to deploy the gateway:

```sh
ssh alisher@2.vpsza500.khassanov.xyz 'ping -c 3 10.201.0.2'
ssh alisher@2.vpsza500.khassanov.xyz \
  "curl --connect-timeout 5 -I -H 'Host: ingress.khassanov.xyz' http://10.201.0.2/"
```

Expect an HTTPS redirect after TLS recovery. Finish with external
[DNS/CAA and HTTPS checks](DNS.md#verify).

## TODO

- [DNS.md](./DNS.md) and [SECURITY.md](./SECURITY.md) are AI-generated. Rework
  after publishing the first service.
