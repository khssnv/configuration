{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disk-config.nix
  ];

  boot.loader.grub.enable = true;

  # Enables legacy IPv4 NAT for <https://hub.docker.com/r/kylemanna/openvpn>.
  boot.kernelPatches = [
    {
      name = "openvpn-legacy-nat";
      patch = null;
      structuredExtraConfig = {
        NETFILTER_XTABLES_LEGACY = lib.kernel.yes;
        IP_NF_IPTABLES_LEGACY = lib.kernel.module;
        IP_NF_NAT = lib.kernel.module;
      };
    }
  ];
  boot.kernelModules = [ "iptable_nat" ];

  zramSwap.enable = true;

  networking = {
    hostName = "1";
    domain = "hostkey.khassanov.xyz";
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
    pkgs.ncdu
  ];

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

  users.users =
    let
      sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLB7lnUc9iy4UYdAl5q2qmrB1VEuRMcucluAe6WFpYV a.khssnv@gmail.com";
    in
    {
      alisher = {
        isNormalUser = true;
        description = "Alisher Khassanov";
        shell = pkgs.zsh;
        extraGroups = [
          "docker"
          "wheel"
        ];
        openssh.authorizedKeys.keys = [ sshPublicKey ];
      };

      root.openssh.authorizedKeys.keys = [ sshPublicKey ];
    };

  virtualisation.docker.enable = true;

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
