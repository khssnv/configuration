{ config, ... }:

{
  imports = [
      ./hardware.nix
      ./network.nix
      ./programs.nix
      ./services.nix
      ./users.nix
  ];

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Helsinki";

  system = {
    stateVersion = "19.09";
    autoUpgrade.enable = true;
  };

  # security.acme.certs = {
  #   "khassanov.me".email = "a.khssnv@gmail.com";
  # };
}
