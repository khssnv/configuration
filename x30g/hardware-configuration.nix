# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/95825efb-c525-418b-9b82-cb08ac3c8a6a";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/2494-E99E";
      fsType = "vfat";
    };

  fileSystems."/home/ops/Storage" =
    { device = "/dev/disk/by-uuid/c1fde66d-1888-40a4-9065-ec920fc394b6";
      fsType = "ext4";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/64d7ac5a-c9c9-4fb8-9093-ecea3fa6e355"; }
    ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
