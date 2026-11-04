# Rebuild and activate the current NixOS host configuration.
switch:
    sudo nixos-rebuild switch --flake ./nixos

delete-old:
    sudo nix-collect-garbage --delete-older-than 30d
