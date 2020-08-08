{ lib, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
    ];

  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    loader.efi.canTouchEfiVariables = true;
    loader.grub = {
      enable = true;
      version = 2;
      efiSupport = true;
      device = "nodev";
    };
    growPartition = true;
    supportedFilesystems = [ "ntfs" ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/2383ff02-4e12-411c-b7aa-77ce58654268";
    fsType = "btrfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/DD78-577E";
    fsType = "vfat";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/48453d46-ba39-4c44-a0f2-c1aea94aa5ec"; } ];

  zramSwap.enable = true;
  nix.maxJobs = lib.mkDefault 4;
  time.timeZone = "Europe/Madrid";
}
