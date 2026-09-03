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

#### Wallpapers

Copies GNOME wallpapers from NAS. The light wallpaper is used for the light
theme, and the dark wallpaper is used for the dark theme.

```console
bootstrap-wallpapers
```

Defined in [wallpaper.nix](wallpaper.nix).
