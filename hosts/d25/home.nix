{ pkgs, ... }:

{
  imports = [
    ../home.nix
    ./gnome.nix
  ];

  home = {
    # Keep host lifecycle versions local even while their current values match.
    stateVersion = "26.05";

    packages = [ pkgs.zed-editor ];
  };
}
