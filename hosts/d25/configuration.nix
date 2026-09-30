{ hostName, userName, ... }:

{
  imports = [
    ../configuration.nix
    ./hardware-configuration.nix
    ./modules/benq-display-pilot-2
    ./modules/ddcci-backlight
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    initrd.luks.devices."luks-d5bab83e-ca6a-465a-bd76-545b83ca306d".device = "/dev/disk/by-uuid/d5bab83e-ca6a-465a-bd76-545b83ca306d";
    resumeDevice = "/dev/mapper/luks-d5bab83e-ca6a-465a-bd76-545b83ca306d";
  };

  networking.hostName = hostName;

  services.benqDisplayPilot2 = {
    enable = true;
    user = userName;
    autostart = {
      enable = true;
      startMinimizedToTray = true;
    };
  };

  hardware.ddcciBacklight.enable = true;

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

  # USB UPS (Eaton 5E), see README.md. UPower falls back to its defaults
  # unless the thresholds are in descending order. Mice, keyboards and
  # touchpads use UPower's fixed thresholds instead.
  services.upower = {
    percentageLow = 70;
    percentageCritical = 60;
    percentageAction = 50;
  };

  # Keep host lifecycle versions local even while their current values match.
  system.stateVersion = "26.05";
}
