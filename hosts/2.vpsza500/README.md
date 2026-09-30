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

1. Install NixOS. The installation repartitions `/dev/vda`.

    ```console
    nix run github:nix-community/nixos-anywhere -- \
      --flake .#2.vpsza500 \
      --target-host root@2.vpsza500.khassanov.xyz
    ```

See nixos-anywhere docs at <https://nix-community.github.io/nixos-anywhere/quickstart.html>.

## Apply configuration remotely

1. Generate and set `token` in [syncthing-relay.nix](syncthing-relay.nix).

    ```console
    nix run nixpkgs#openssl -- rand -base64 48
    ```

1. Apply configuration remotely.

    ```console
    nixos-rebuild switch \
      --flake .#2.vpsza500 \
      --target-host alisher@2.vpsza500.khassanov.xyz \
      --ask-sudo-password
    ```

1. Get relay ID on the remote machine from logs.

    ```console
    journalctl -u syncthing-relay.service -b | grep -i id
    ```

## Syncthing Relay

Add the relay in Syncthing GUI:
`Actions -> Settings -> Connections -> Sync Protocol Listen Addresses`.

Keep existing listen addresses and append:

```text
relay://2.vpsza500.khassanov.xyz:22067/?id=<relay-device-id>&token=<token-from-syncthing-relay.nix>
```
