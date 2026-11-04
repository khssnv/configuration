# rockpix

YouTube kiosk.

## Apply configuration remotely

```console
nixos-rebuild switch \
  --flake .#rockpix \
  --target-host alisher@rockpix.lan \
  --ask-sudo-password
```
