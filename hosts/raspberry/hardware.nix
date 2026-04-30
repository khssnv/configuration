{ config, lib, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.pulseaudio.enable = true; # for sound

  fileSystems."/" = {
      device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
      fsType = "ext4";
  };

  swapDevices = [ { device = "/swapfile"; size = 1024; } ];
  zramSwap.enable = true;

  nix.maxJobs = lib.mkDefault 1;
}
