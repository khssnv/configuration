{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}@args:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
    ./syncthing-relay.nix
  ];

  services.qemuGuest.enable = true;

  networking = {
    hostName = "2";
    domain = "vpsza500.khassanov.xyz";
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

  users.users =
    let
      sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLB7lnUc9iy4UYdAl5q2qmrB1VEuRMcucluAe6WFpYV a.khssnv@gmail.com";
    in
    {
      alisher = {
        isNormalUser = true;
        description = "Alisher Khassanov";
        shell = pkgs.zsh;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [ sshPublicKey ];
      };

      root.openssh.authorizedKeys.keys = [ sshPublicKey ];
    };

  programs.zsh.enable = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "alisher" ];
  };

  nixpkgs.config.allowUnfree = true;

  zramSwap.enable = true;

  system.stateVersion = "24.05";
}
