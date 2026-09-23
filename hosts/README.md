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

#### Syncthing Tray

Writes the Syncthing connection (GUI address and API key from the local
Syncthing config) to the Syncthing Tray settings, so its setup wizard is not
shown. Run it after Syncthing has started at least once, and quit Syncthing
Tray first, because it rewrites its settings on exit.

```console
bootstrap-syncthingtray
```

Defined in [syncthing.nix](syncthing.nix).

#### Wallpapers

Copies GNOME wallpapers from NAS. The light wallpaper is used for the light
theme, and the dark wallpaper is used for the dark theme.

```console
bootstrap-wallpapers
```

Defined in [wallpaper.nix](wallpaper.nix).
