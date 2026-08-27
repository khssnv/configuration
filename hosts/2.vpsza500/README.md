# 2.vpsza500

## NixOS Anywhere docs

<https://nix-community.github.io/nixos-anywhere/quickstart.html>

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
