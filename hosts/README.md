# configuration/hosts

## NixOS hosts

### Bootstrap

#### SSH key

Desktops decrypt secrets with `~/.ssh/id_ed25519`, its age recipient is the
`&alisher` key in [.sops.yaml](.sops.yaml). Put the key in place before
applying the configuration. sops-nix cannot use a key with a passphrase.

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

## Secrets

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix).

### Add or change a secret

```console
sops edit secrets.yaml
```

Nested YAML keys map to secret names joined with `/`, e.g. `token` under
`syncthing-relay` is `syncthing-relay/token`. Declare the secret in the module
that reads it:

```nix
sops.secrets."syncthing-relay/token" = { };
```

Desktops use the sops-nix home-manager module, see [home.nix](home.nix). The
`sops-nix` user service decrypts secrets with `~/.ssh/id_ed25519`, so user
services reading a secret order after `sops-nix.service`. The server uses the
NixOS module with its SSH host key.

### Re-encrypt for a new host key

Needed when a host gets a new SSH host key. The steps below use
`2.vpsza500.khassanov.xyz` as an example.

1. Get the host key fingerprint through a trusted channel, such as the hosting
    provider's console. On the server, run:

    ```console
    ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub -E sha256
    ```

1. Fetch the public host key on the local machine and print its fingerprint:

    ```console
    ssh-keyscan -t ed25519 2.vpsza500.khassanov.xyz > ssh_host_ed25519_key.pub
    ssh-keygen -lf ssh_host_ed25519_key.pub -E sha256
    ```

    Compare the complete SHA256 fingerprints. Do not continue unless they
    match.

1. Convert the verified public host key to an age recipient:

    ```console
    nix run nixpkgs#ssh-to-age -- -i ssh_host_ed25519_key.pub
    ```

    The desktop recipient can be derived separately from the user's
    `~/.ssh/id_ed25519.pub` or use SSH public key directly.

1. Replace the `&2-vpsza500` key in [.sops.yaml](.sops.yaml) with the output.

1. Re-encrypt the data key for the updated recipients.

    ```console
    sops updatekeys secrets.yaml
    ```

1. Commit and apply the server configuration.

A new server is added the same way, with a new key referenced in
`creation_rules`. Desktops share the `&alisher` key.

### References

- sops-nix: <https://github.com/Mic92/sops-nix>
- SOPS: <https://getsops.io/docs/>
- Vimjoyer, NixOS secrets management with sops-nix:
  <https://youtu.be/G5f6GC7SnhU>
