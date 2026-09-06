{ lib, pkgs, ... }:

let
  idleDelay = 3600;
  rotki = pkgs.callPackage ./pkgs/rotki.nix { };
in
{
  imports = [
    ../home.nix
    (import ./gnome.nix { inherit idleDelay lib; })
  ];

  home = {
    # Keep host lifecycle versions local even while their current values match.
    stateVersion = "26.05";

    packages = [
      pkgs.zed-editor
      rotki
    ];
  };

  programs.keepassxc.settings.Security.LockDatabaseIdleSeconds = idleDelay;
}
