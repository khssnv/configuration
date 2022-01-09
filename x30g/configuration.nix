{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      (fetchTarball "https://github.com/msteen/nixos-vscode-server/tarball/master")
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  zramSwap.enable = true;

  # Put HDD into idle mode in 5 minutes
  powerManagement.powerUpCommands = ''
    ${pkgs.hdparm}/sbin/hdparm -S 60 /dev/sdb
  '';

  time.timeZone = "Europe/Samara";

  networking = {
    hostName = "x30g";
    interfaces = {
      enp1s0.useDHCP = true;
      enp3s0.useDHCP = true;
      wlp2s0.useDHCP = true;
    };
    wireless.enable = true;
    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [ 
        22 # ssh
      ];
    };
  };

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  services = {
    timesyncd = {
      enable = true;
      servers = [ "0.pool.ntp.org" "1.pool.ntp.org" ];
    };
    openssh = {
      enable = true;
      passwordAuthentication = false;
      permitRootLogin = "no";
    };
    vscode-server.enable = true;
    yggdrasil = {
      enable = true;
      persistentKeys = true;
      config = {
        Peers = [
          "tcp://ygg-ru.cofob.ru:18000"
          "tcp://ygg-ru2.cofob.ru:80"
          "tcp://ygg.loskiq.dev:17313"
          "tcp://yggnode.cf:18226"
          "tls://ygg-ru2.cofob.ru:443"
          "tls://yggnode.cf:18227"
          "tls://ygg.loskiq.dev:17314"
        ];
      };
    };
  };

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  users.users.ops = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/ops";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLB7lnUc9iy4UYdAl5q2qmrB1VEuRMcucluAe6WFpYV khassanov"
    ];
  };

  environment.systemPackages = with pkgs; [
    git
    htop
    ncdu
    neovim
    wget
    nixpkgs-fmt # required by vscode "Nix IDE" plugin
    parted
  ];

  nixpkgs.config.allowUnfree = true;

  nix = {
    trustedUsers = [ "ops" ];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  system = {
    stateVersion = "21.11";
    autoUpgrade.enable = true;
  };
}
