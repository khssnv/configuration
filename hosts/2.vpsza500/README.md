# 2.vpsza500

## Bootstrap using nixos-anywhere

1. Set up a GNU / Linux machine with SSH access as `root`.

1. Get the network configuration of the target machine and set it in
    [configuration.nix](configuration.nix).

    On the target machine:

    ```console
    ip -4 -o address show scope global
    ip -4 route show default
    ```

    Example output:

    ```console
    root@vds38892:~# ip -4 -o address show scope global
    2: ens3    inet 92.38.49.12/23 brd 92.38.49.255 scope global ens3\       valid_lft forever  preferred_lft forever
    root@vds38892:~# ip -4 route show default
    default via 92.38.48.1 dev ens3 onlink
    ```

    Set the interface name, `address`, `prefixLength` and `defaultGateway` in
    the `networking` section accordingly.

1. Follow
    [Re-encrypt for a new host key](../README.md#re-encrypt-for-a-new-host-key)
    to re-encrypt secrets for the new SSH host key in case the old one is lost.

1. Install NixOS. The installation repartitions `/dev/vda`.

    ```console
    nix run github:nix-community/nixos-anywhere -- \
      --copy-host-keys \
      --flake .#2.vpsza500 \
      --target-host root@2.vpsza500.khassanov.xyz
    ```

See nixos-anywhere docs at <https://nix-community.github.io/nixos-anywhere/quickstart.html>.

## Apply configuration remotely

```console
nixos-rebuild switch \
  --flake .#2.vpsza500 \
  --target-host alisher@2.vpsza500.khassanov.xyz \
  --ask-sudo-password
```

## Syncthing Relay

NixOS desktops get the relay address from [syncthing.nix](../syncthing.nix).
The relay ID changes on reinstallation, update `relayId` there. Get the ID on
the remote machine:

```console
journalctl -u syncthing-relay.service -b | grep -i id
```

On other devices, add the relay in Syncthing GUI:
`Actions -> Settings -> Connections -> Sync Protocol Listen Addresses`.

Keep existing listen addresses and append:

```text
relay://2.vpsza500.khassanov.xyz:22067/?id=<relay-device-id>&token=<token>
```

Print the token from the `hosts` directory:

```console
sops decrypt --extract '["syncthing-relay"]["token"]' secrets.yaml
```

### Rotate the token

The token is `syncthing-relay/token` in [secrets.yaml](../secrets.yaml). Set a
new one from the `hosts` directory, then apply this host and the desktops. The
desktops pick up the new token only when `syncthing-init` runs again, on login
or on restart.

```console
printf '"%s"' "$(nix run nixpkgs#openssl -- rand -hex 32)" \
  | sops set --value-stdin secrets.yaml '["syncthing-relay"]["token"]'
# on each desktop after applying
systemctl --user restart syncthing-init.service
```

On other devices, replace the token in the relay listen address.
