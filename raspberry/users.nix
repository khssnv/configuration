{ pkgs, ... }:

let
  home-manager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
    rev = "f5c9303cedd67a57121f0cbe69b585fb74ba82d9";
    ref = "release-19.09";
  };
  vim_custom = pkgs.vim_configurable.override {
    python = pkgs.python36Full;
  };

in
{
  imports = [
      (import "${home-manager}/nixos")
  ];

  users.extraUsers.khassanov = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/khassanov";
    description = "Alisher A. Khassanov";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
  };

  home-manager.users.khassanov = with pkgs; {
    home.packages = [
      vim_custom
      tmux
      ncdu
      mc
      git
      htop
    ];

    programs = {
      home-manager.enable = true;
      git = {
        enable = true;
        userName = "Alisher A. Khassanov";
        userEmail = "a.khssnv@gmail.com";
      };

      zsh = {
        enable = true;
        oh-my-zsh = {
          enable = true;
          theme = "bira";
          plugins = [ "git" ];
        };
      };
    };
  };

  users.extraUsers.khassanov.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLB7lnUc9iy4UYdAl5q2qmrB1VEuRMcucluAe6WFpYV khassanov@32vd"
  ];

  users.extraUsers.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLB7lnUc9iy4UYdAl5q2qmrB1VEuRMcucluAe6WFpYV khassanov@32vd"
  ];
}
