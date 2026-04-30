{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ./network.nix
    ./programs.nix
    ./services.nix
    ./users.nix
  ];

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.raspberryPi = {
    enable = true;
    version = 3;
    uboot.enable = true;
    firmwareConfig = ''
      hdmi_force_hotplug=1
    '';
  };
  boot.initrd.availableKernelModules = [ "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "cma=32M" # recommended by installation guide
    "console=ttyS1,115200n8" # UART console
  ];
  boot.kernelModules = [
    "bcm2835-v4l2" # for camera
  ];

  i18n = {
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "Europe/Madrid";

  sound.enable = true;

  # https://github.com/NixOS/nixpkgs/issues/54946
  systemd.services.nixos-upgrade.path = [ pkgs.git ];

  system.stateVersion = "19.09";
}
