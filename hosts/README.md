# configuration/hosts

## NixOS hosts

### Bootstrap

#### Apply configuration

```console
HOSTNAME=<bootstrap_host_name>
sudo nixos-rebuild switch --flake ".#$HOSTNAME"
```

#### GoldenDict dictionaries

Copies dictionaries from NAS. GoldenDict takes some time to index them.

```console
bootstrap-goldendict-dictionaries
```

Defined in [goldendict.nix](goldendict.nix).
