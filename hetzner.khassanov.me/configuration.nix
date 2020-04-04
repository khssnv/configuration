{ config, ... }:

let
  confPath = "/etc/nixos/hetzner.khassanov.me";

in
{
  imports = [
      "${confPath}/hardware.nix"
      ./network.nix
      ./programs.nix
      ./services.nix
      "${confPath}/users.nix"
  ];

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Helsinki";

  system = {
    stateVersion = "19.09";
    autoUpgrade.enable = true;
  };

  nix = {
    trustedUsers = ["khassanov"];
  };

  # security.acme.certs = {
  #   "khassanov.me".email = "a.khssnv@gmail.com";
  # };
}
