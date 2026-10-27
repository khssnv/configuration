{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.grub.device = "/dev/vda";

  networking.hostName = "ingress";

  security.sudo.wheelNeedsPassword = false;

  services.qemuGuest.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

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
