# AGENTS.md

This repository contains personal configuration files and infrastructure
automation.

- Use `caveman` skill.
- After editing Markdown files, run `rumdl check --fix <file>`.

## Project map

Start with the relevant area's README and local agent instructions, then follow
configuration imports.

- [ansible/](ansible/README.md) — host bootstrap, Nextcloud, and UPS
  automation. `inventories/` holds host and group configuration;
  `playbooks/` contains the numbered operations.
- [docs/worktrunk.md](docs/worktrunk.md) — Git worktree workflow and
  customization, with settings in
  [dotfiles/worktrunk/config.toml](dotfiles/worktrunk/config.toml).
- [dotfiles/](dotfiles/) — shell, Git, editor, and terminal settings.
  [install.sh](dotfiles/install.sh) installs standalone dotfiles;
  NixOS modules also reference files in this directory.
- [nixos/](nixos/) — NixOS and Home Manager configurations. Read the
  [local agent instructions and module map](nixos/AGENTS.md) and
  [setup guide](nixos/README.md). The shared [flake](nixos/flake.nix)
  defines `d25`, `ux32vd`, and `x1`; `ingress/`, `hypervisor/`,
  `rockpix/`, and `2.vpsza500/` have separate flakes and READMEs.
- [rae/](rae/README.md) — Luxonis RAE robot configuration with Ansible.
  [config-dump/](rae/config-dump/README.md) collects snapshots and renders
  [init-config-dump.md](rae/init-config-dump.md); edit the snapshots or
  renderer rather than the generated report.
- [scripts/](scripts/) — PDF compression, scan postprocessing, and
  [Worktrunk local-file copying](scripts/wt-copy-local/README.md).
- [terraform/](terraform/README.md) — Proxmox VM provisioning.
  `ingress.tf` and `hypervisor.tf` define the VMs configured by
  [nixos/ingress/](nixos/ingress/README.md) and
  [nixos/hypervisor/](nixos/hypervisor/README.md).

## Git Commit Message

- Never use Conventional Commits.
- Max subject length: 50 characters.
- Max body line length: 72 characters.
- Follow the style of recent commits.
- Run `git --no-pager log -n 10 --format=%s`for examples.
