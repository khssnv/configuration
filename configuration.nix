{ config, ... }:

let

  host = "ux32vd";

in
{
  imports = [
      "./${host}/hardware.nix"
      "./${host}/network.nix" { hostname = host; };
      "./${host}/programs.nix"
      "./${host}/services.nix"
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

