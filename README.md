Configuration
=============

My configuration files.

Ubuntu setup
------------

```console
curl -L https://nixos.org/nix/install | sh
. /home/$USER/.nix-profile/etc/profile.d/nix.sh
nix-channel --add https://github.com/rycee/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
rm /home/$USER/.config/nixpkgs/home.nix
mkdir ~/Workspace && cd ~/Workspace
git clone https://github.com/khssnv/configuration.git
cd configuration
ln -s ~/Workspace/configurationi/home.nix ~/.config/nixpkgs/home.nix
home-manager switch
sudo chsh -s "$(command -v zsh)" "${USER}"
```

NixOS setup
-----------

1. Edit `hardware.nix` considering machine `hardware-configuration.nix`
2. Replace /etc/nixos with symlink to local repo copy

