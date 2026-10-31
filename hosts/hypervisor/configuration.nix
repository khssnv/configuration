{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.grub.device = "/dev/vda";

  networking.hostName = "hypervisor";

  security.sudo.wheelNeedsPassword = false;

  services.qemuGuest.enable = true;

  # TODO: Move ens19 and the TrueNAS storage interface to a dedicated subnet.
  # Both interfaces currently use 192.168.1.0/24.
  # Route TrueNAS storage traffic explicitly through ens19.
  networking = {
    interfaces.ens19.ipv4.routes = [
      {
        address = "192.168.1.153";
        prefixLength = 32;
      }
    ];

    dhcpcd.extraConfig = ''
      interface ens19
        nogateway
        nohook resolv.conf
    '';
  };

  # Answer ARP requests only for addresses assigned to the receiving interface.
  boot.kernel.sysctl = {
    "net.ipv4.conf.ens18.arp_ignore" = 1;
    "net.ipv4.conf.ens19.arp_ignore" = 1;
  };

  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Bind the listener to the administrative interface without fixing its DHCP address.
  systemd.sockets.sshd.socketConfig.BindToDevice = "ens18";

  networking.firewall.interfaces.ens18.allowedTCPPorts = config.services.openssh.ports;

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

  programs.zsh = {
    enable = true;
    promptInit = ''
      HOST=${lib.escapeShellArg config.networking.fqdnOrHostName}
      PROMPT=''${PROMPT//\%m/\%M}
    '';
    ohMyZsh = {
      enable = true;
      theme = "ys";
    };
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "alisher" ];
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.05";
}
