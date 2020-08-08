{ config, pkgs, ... }:

{
  services = {
    # openssh = {
    #   enable = true;
    #   passwordAuthentication = false;
    #   permitRootLogin = "yes";
    # };
    
    ntp = {
      enable = true;
      servers = [ "0.pool.ntp.org" "1.pool.ntp.org" ];
    };

    xserver = {
      enable = true;
      layout = "us";
      xkbOptions = "eurosign:e";
      videoDrivers = [ "modesetting" "nvidia" ];
      libinput.enable = true; # touchpad
      displayManager.sddm.enable = true;
      desktopManager.plasma5.enable = true;
    };
  };
}
