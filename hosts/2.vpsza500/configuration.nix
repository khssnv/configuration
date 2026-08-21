{
  modulesPath,
  lib,
  pkgs,
  ...
}@args:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  services.qemuGuest.enable = true;

  networking = {
    useDHCP = false;
    interfaces.ens3.ipv4.addresses = [
      {
        address = "93.171.232.142";
        prefixLength = 23;
      }
    ];
    defaultGateway = {
      address = "93.171.232.1";
      interface = "ens3";
    };
    nameservers = [
      "1.1.1.1"
      "9.9.9.9"
    ];
  };

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
    services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
    pkgs.htop
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLB7lnUc9iy4UYdAl5q2qmrB1VEuRMcucluAe6WFpYV a.khssnv@gmail.com"
  ];

  system.stateVersion = "24.05";
}
