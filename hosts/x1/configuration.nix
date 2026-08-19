{ hostName, ... }:

{
  imports = [
    ../configuration.nix
    ./hardware-configuration.nix
  ];

  boot = {
    loader.systemd-boot = {
      enable = true;
      consoleMode = "1";
    };
    loader.efi.canTouchEfiVariables = true;
  };

  networking.hostName = hostName;

  # Static location for desktop features using sunrise/sunset. Coordinates are
  # the Asia/Almaty representative point from tzdata's zone1970.tab
  # ("+4315+07657"), not an exact address. Setting enableStatic disables
  # network-assisted location sources.
  services.geoclue2 = {
    enableStatic = true;
    staticLatitude = 43.25;
    staticLongitude = 76.95;
    staticAltitude = 800;
    staticAccuracy = 20000;
  };

  # Keep host lifecycle versions local even while their current values match.
  system.stateVersion = "26.05";
}
