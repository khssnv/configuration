{
  imports = [
    ../home.nix
    ./gnome.nix
  ];

  # Keep host lifecycle versions local even while their current values match.
  home.stateVersion = "26.05";
}
