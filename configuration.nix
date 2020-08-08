{ config, pkgs, ... }:

let

  host = "ux32vd";

in
{
  imports = [
    (/etc/nixos + "/${host}/hardware.nix")
    (import (/etc/nixos + "/${host}/network.nix") ({ hostname = host; })) 
    # (/etc/nixos + "/${host}/network.nix")
    (/etc/nixos + "/${host}/programs.nix")
    (/etc/nixos + "/${host}/services.nix")
    ./users.nix
  ];

  nixpkgs.config.allowUnfree = true;

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  environment.systemPackages = with pkgs; [
    htop
    wget
    neovim
  ];

  system = {
    stateVersion = "20.03";
    autoUpgrade.enable = true;
  };

  nix = {
    trustedUsers = [ "khassanov" ];
  };
}

