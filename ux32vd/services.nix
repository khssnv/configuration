{ config, pkgs, ... }:

{
  services = {
    xserver = {
      enable = true;
      layout = "us";
      xkbOptions = "eurosign:e";
      videoDrivers = [ "modesetting" "intel" "nvidiaLegacy390" ];
      libinput.enable = true; # touchpad
      displayManager.sddm.enable = true;
      desktopManager.plasma5.enable = true;
    };
  };
}
