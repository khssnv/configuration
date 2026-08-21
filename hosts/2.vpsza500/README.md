# 2.vpsza500

## NixOS Anywhere docs

<https://nix-community.github.io/nixos-anywhere/quickstart.html>

## Apply configuration remotely

```console
nixos-rebuild switch \
  --flake .#generic \     
  --target-host root@2.vpsza500.khassanov.xyz
```
