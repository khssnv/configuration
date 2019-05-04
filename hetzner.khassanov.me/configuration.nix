{ config, pkgs, ... }:

{
  imports = [
      ./hardware.nix
      ./services.nix
      ./programs.nix
      ./network.nix
      ./users.nix
      # "${builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz}/nixos" # home manager
      # /home/khassanov/Workspace/mysysdsrv/mysysdsrv.nix
  ];

  system = {
    stateVersion = "19.03";
    autoUpgrade.enable = true;
  };

  #security.acme.certs = {
  #  "khassanov.me".email = "a.khssnv@gmail.com";
  #};
}
