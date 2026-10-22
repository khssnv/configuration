# AGENTS.md

## Project map

Paths below are relative to `hosts/`.

- `flake.nix`, `flake.lock` — shared entry point and dependencies for `d25`,
  `ux32vd`, and `x1`; outputs are `nixosConfigurations.<host>`.
- `configuration.nix` — shared NixOS settings for these three hosts:
  system services, networking, users, and system packages.
- `home.nix` — shared Home Manager settings, user packages,
  and application module imports.
- `gnome.nix`, `wallpaper.nix` — shared GNOME and wallpaper settings.
- `d25/`, `ux32vd/`, `x1/` — settings for individual hosts:
  `configuration.nix` imports the shared system configuration,
  `home.nix` imports the shared user configuration; `gnome.nix` contains
  the host's GNOME settings, and `hardware-configuration.nix` is generated hardware configuration.
- `agents.nix`, `vscode.nix`, `worktrunk.nix`, `starship.nix` — settings
  for coding agents, the editor, Git worktrees, and the shell prompt.
- `goldendict.nix`, `simple-scan.nix`, `syncthing.nix` — respective applications;
  `shares.nix` — network file shares.
- `d25/modules/`, `d25/pkgs/` — hardware modules and packages for `d25`.
- `rockpix/` — separate flake for the YouTube kiosk;
  `2.vpsza500/` — separate server flake, with `disk-config.nix` for disk partitioning
  and `syncthing-relay.nix` for the Syncthing relay.
- `README.md` and READMEs in host directories — setup and deployment instructions.
  `../dotfiles/`, `../scripts/` — files and scripts referenced by Nix modules.

For a change to one host, start in its directory and follow `imports`.
Changes to shared modules affect every host that imports them.
