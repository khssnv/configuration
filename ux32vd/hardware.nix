{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "ehci_pci" "ahci" "usb_storage" "sd_mod" "rtsx_usb_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.loader.grub = {
    enable = true;
    useOSProber = true;
    efiSupport = true;
    device = "nodev";
  };
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.supportedFilesystems = [ "ntfs" ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/af19317c-f99e-445f-897e-7b84ffdc2c31";
      fsType = "btrfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/88B2-13EE";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/1a46b975-a6c2-464f-bccc-8134ddbc5dfd"; }
    ];

  nix.maxJobs = lib.mkDefault 2;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  time = {
    timeZone = "Europe/Madrid";
    hardwareClockInLocalTime = true;
  };

  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.nvidia.prime = {
    sync.enable = true;
    nvidiaBusId = "PCI:1:0:0";
    intelBusId = "PCI:0:2:0";
  };
}

