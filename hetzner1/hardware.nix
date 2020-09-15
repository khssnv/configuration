{ lib, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
    ];

  boot = {
    initrd.availableKernelModules = [ "ata_piix" "virtio_pci" "xhci_pci" "sd_mod" "sr_mod" ];
    kernelModules = [ ];
    extraModulePackages = [ ];
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/sda";
    };
    growPartition = true;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/ceb2628d-3e46-43ea-9549-b137be36d8eb";
    fsType = "btrfs";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/1c13b814-0e2a-4ab9-8a3f-3737ebb1f02d"; } ];

  zramSwap.enable = true;
  nix.maxJobs = lib.mkDefault 1;
}
