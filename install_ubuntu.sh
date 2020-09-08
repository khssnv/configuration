#!/usr/bin/env bash

curl -L https://nixos.org/nix/install | sh
. /home/$USER/.nix-profile/etc/profile.d/nix.sh
nix-channel --add https://github.com/rycee/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
rm /home/$USER/.config/nixpkgs/home.nix
ln -s /home/$USER/configuration/home.nix ~/.config/nixpkgs/home.nix
home-manager switch
sudo chsh -s "$(command -v zsh)" "${USER}"
