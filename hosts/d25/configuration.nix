{
  hostName,
  lib,
  pkgs,
  userName,
  ...
}:

{
  imports = [
    ../configuration.nix
    ./hardware-configuration.nix
    ./vllm.nix
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

  # Liberation is already included in the default system fonts.
  fonts.packages = with pkgs; [
    carlito # Metric-compatible replacement for Calibri.
    caladea # Metric-compatible replacement for Cambria.
    noto-fonts-lgc-plus # Latin, Greek, Cyrillic, symbols, and math fonts.
    noto-fonts-color-emoji # Color emoji.
  ];

  services.benqDisplayPilot2 = {
    enable = true;
    user = userName;
    autostart = {
      enable = true;
      startMinimizedToTray = true;
    };
  };

  hardware.ddcciBacklight = {
    enable = true;
    monitors = [ "BenQ RD280UG" ];
  };

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

  # Disable netdata autostart; start until reboot with `systemctl start netdata` as root.
  # systemd.services.netdata.wantedBy = lib.mkForce [ ];

  # Polling Docker 29+ every second causes high dockerd/containerd CPU usage. See
  # https://github.com/moby/moby/issues/53077, https://github.com/netdata/netdata/releases/tag/v2.12.1.
  # TODO: Remove after upgrading Netdata to >= 2.12.1, which caches the image
  # list for five minutes and defaults to a ten-second collection interval.
  services.netdata.configDir."go.d/docker.conf" = pkgs.writeText "netdata-docker.conf" ''
    jobs:
      - name: local
        address: unix:///var/run/docker.sock
        update_every: 10
  '';

  # Keep host lifecycle versions local even while their current values match.
  system.stateVersion = "26.05";
}
