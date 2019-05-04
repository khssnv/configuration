{ lib, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
    ];

  boot = {
    initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sd_mod" "sr_mod" ];
    kernelModules = [ ];
    extraModulePackages = [ ];
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/sda";
    };
  };

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/cafbb945-aef6-4a89-9274-7d01c9381b0b";
      fsType = "btrfs";
    };

  swapDevices = [ ];
  zramSwap.enable = true;
  nix.maxJobs = lib.mkDefault 1;
}
