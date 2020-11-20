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
      displayManager.gdm.enable = true;
      desktopManager.gnome3.enable = true;
    };
  };
}
