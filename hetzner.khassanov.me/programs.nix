{ pkgs, ... }:

{
  programs = {
    mosh.enable = true;
    zsh = {
      enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      autosuggestions.enable = true;
      ohMyZsh = {
        enable = true;
        theme = "bira";
        plugins = [ "git" ];
      };
    };
    vim.defaultEditor = true;
  };

  environment.systemPackages = with pkgs; [
    wget curl htop tmux vim git zsh nmap ncdu
  ];
}
