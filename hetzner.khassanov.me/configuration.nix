{ config, pkgs, ... }:

{
  imports = [
      ./hardware.nix
      ./services.nix
      ./programs.nix
      ./network.nix
      ./users.nix
  ];

  system = {
    stateVersion = "19.03";
    autoUpgrade.enable = true;
  };

  # security.acme.certs = {
  #   "khassanov.me".email = "a.khssnv@gmail.com";
  # };

}
