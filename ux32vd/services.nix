{ config, pkgs, ... }:

{
  services = {
    teamviewer.enable = true;
    xserver = {
      enable = true;
      layout = "us";
      xkbOptions = "eurosign:e";
      videoDrivers = [ "intel" ];
      libinput.enable = true; # touchpad
      displayManager.sddm.enable = true;
      desktopManager.plasma5.enable = true;
    };
  };
}
