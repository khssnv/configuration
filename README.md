# Configuration

My configuration files.

## Eaton 5E 850i UPS

Add kernel boot parameter (via GRUB etc.): `usbhid.quirks=0x0463:0xffff:0x08`.
See <https://github.com/networkupstools/nut/commit/a6b29f36fbc6acc8d2e2221dbf7c1053392232b5>.

## NixOS hosts

### Bootstrap

#### Apply configuration

```console
HOSTNAME=<bootstrap_host_name>
sudo nixos-rebuild switch --flake "./hosts#$HOSTNAME"
```

#### GoldenDict dictionaries

Copies dictionaries from NAS. GoldenDict takes some time to index them.

```console
bootstrap-goldendict-dictionaries
```

Defined in [goldendict.nix](hosts/goldendict.nix).
