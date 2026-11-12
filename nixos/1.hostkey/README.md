# 1.hostkey

## Apply configuration remotely

```console
nixos-rebuild switch \
  --flake .#1.hostkey \
  --target-host alisher@1.hostkey.khassanov.xyz \
  --ask-sudo-password
```
