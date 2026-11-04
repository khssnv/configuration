{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./nginx.nix
    ./wireguard.nix
  ];

  boot.loader.grub.device = "/dev/vda";

  networking.hostName = "ingress";

  security.sudo.wheelNeedsPassword = false;

  services.qemuGuest.enable = true;

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
