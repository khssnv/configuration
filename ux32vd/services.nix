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
      desktopManager = {
        xterm.enable = false;
        xfce.enable = true;
      };
      displayManager.defaultSession = "xfce";
    };
  };
}
