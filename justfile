# Rebuild and activate the current NixOS host configuration.
switch:
    sudo nixos-rebuild switch --flake ./hosts
