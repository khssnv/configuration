{ hostName, ... }:

{
  imports = [
    ../configuration.nix
    ./hardware-configuration.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    initrd.luks.devices."luks-efbfbd18-6370-44b1-a4d0-1de3f0ea6b66".device =
      "/dev/disk/by-uuid/efbfbd18-6370-44b1-a4d0-1de3f0ea6b66";
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

  # Expose the built-in ACPI ambient light sensor to GNOME. Its power plugin
  # enables ambient brightness control by default when this proxy is present.
  hardware.sensor.iio.enable = true;

  # Keep host lifecycle versions local even while their current values match.
  system.stateVersion = "26.05";
}
