# AGENTS.md

- The embedded Samba credentials in `shares.nix` are non-secret, reading and
  editing this file is permitted.
- For GNOME autostart, use Home Manager's `xdg.autostart.entries` with
  package-provided `.desktop` files. Create custom entries only when launch
  commands or autostart-related settings must differ.
- Place new configuration options by semantic grouping, importance
  (general/system-level first, specific/user-level later), and locality of
  scope, following existing conventions without reordering or moving existing
  code.

## Project map

Paths below are relative to `nixos/`.

- `flake.nix`, `flake.lock` — shared entry point and dependencies for `d25`,
  `ux32vd`, and `x1`; outputs are `nixosConfigurations.<host>`.
- `configuration.nix` — shared NixOS settings for these three hosts:
  system services, networking, users, and system packages.
- `home.nix` — shared Home Manager settings, user packages,
  and application module imports.
- `gnome.nix`, `wallpaper.nix` — shared GNOME and wallpaper settings.
- `hosts/d25/`, `hosts/ux32vd/`, `hosts/x1/` — settings for individual hosts:
  `configuration.nix` imports `../../configuration.nix`, and `home.nix` imports
  `../../home.nix`; `gnome.nix` contains the host's GNOME settings, and
  `hardware-configuration.nix` is generated hardware configuration.
- `agents.nix`, `vscode.nix`, `worktrunk.nix`, `starship.nix` — settings
  for coding agents, the editor, Git worktrees, and the shell prompt.
- `goldendict.nix`, `simple-scan.nix`, `syncthing.nix` — respective
  applications; `shares.nix` — network file shares.
- `modules/` — reusable Netinstall, DDC/CI backlight, and BenQ Display Pilot 2
  modules. Hosts explicitly import and configure the modules they use.
- `pkgs/` — local package recipes and their supporting files. New package
  recipes belong here rather than inside host directories.
- `hosts/rockpix/` — separate flake for the YouTube kiosk.
- `hosts/1.hostkey/`, `hosts/2.vpsza500/` — separate server flakes, each with
  `disk-config.nix`; `2.vpsza500` also runs the Syncthing relay.
- `hosts/ingress/`, `hosts/hypervisor/` — separate flakes for the ingress VM
  and the KVM/libvirt hypervisor.

For a change to one host, start in its directory and follow `imports`. Changes
to shared modules affect every host that imports them.
