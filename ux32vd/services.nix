{ config, pkgs, ... }:

{
  services = {
    teamviewer.enable = true;
    xserver = {
      enable = true;
      layout = "us,ru";
      xkbOptions = "eurosign:e";
      videoDrivers = [ "intel" ];
      libinput.enable = true; # touchpad
      displayManager.gdm = {
        enable = true;
        wayland = false;
      };
      desktopManager.gnome3.enable = true;
    };
    logind.lidSwitch = "ignore";
    prometheus = {
      enable = true;
      scrapeConfigs = [
        {
          job_name = "node";
          scrape_interval = "10s";
          static_configs = [
            {
              targets = [
                "localhost:9100"
              ];
              labels = {
                alias = "ux32vd.khassanov.me";
              };
            }
          ];
        }
      ];
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [
            "cpu"
            "cpufreq"
            "diskstats"
            "loadavg"
            "meminfo"
          ];
        };
      };
    };
  };
  };
}
