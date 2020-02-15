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
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/a9f01841-cce9-439f-bfcf-bc08146cd417";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/7bdf3841-c2cf-4791-9019-2287fd6060bc"; } ];

  zramSwap.enable = true;
  nix.maxJobs = lib.mkDefault 1;
}
