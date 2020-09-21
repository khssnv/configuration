{ config, pkgs, ... }:

let
  username = "khassanov";

in
{

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # home.sessionVariables.LOCALES_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
  # home.sessionVariables = {
  #   # see: https://github.com/NixOS/nixpkgs/issues/38991#issuecomment-400657551
  #   LOCALE_ARCHIVE_2_11 = "/usr/bin/locale/locale-archive";
  #   LOCALE_ARCHIVE_2_27 = "${pkgs.glibcLocales}/lib/locale/locale-archive";
  # };

  # home.language = let
  #   en = "en_US.UTF-8";
  #   ru = "ru_RU.UTF-8";
  #   es = "es_ES.UTF-8";
  # in {
  #   address = ru;
  #   monetary = ru;
  #   paper = ru;
  #   time = en;
  #   base = en;
  # };
  # https://gist.github.com/peti/2c818d6cb49b0b0f2fd7c300f8386bc3

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    ark # kde archive manager
    busybox # cli utilities
    bmon # network usage monitor
    docker
    docker-compose
    # gitkraken
    gparted
    goldendict
    # gource
    ledger-live-desktop
    libreoffice
    htop
    ncdu # disk usage
    # nvtop
    okular # kde pdf viewer
    opera
    spectacle # kde screenshots
    # (eclipses.eclipseWithPlugins {
    #   eclipse = eclipses.eclipse-cpp;
    #   jvmArgs = [ "-Xmx2048m" ];
    #   plugins = with eclipses.plugins;
    #     [ cdt ];
    # })
    kate # kde notes
    ktorrent # kde torrents
    steam
    spotify

    # instant messaging and calls
    element-desktop # matrix messaging
    skype
    slack
    zoom-us
    tdesktop # telegram
    vlc
    discord
    xclip
    # zsh
    unrar
    webcamoid
  ];
  programs = {
    command-not-found.enable = true;
    tmux = {
      enable = true;
      plugins = with pkgs; [
        tmuxPlugins.cpu
        {
          plugin = tmuxPlugins.resurrect;
          extraConfig = "set -g @resurrect-strategy-nvim 'session'";
        }
      ];
      extraConfig = ''
	      source /home/${username}/Workspace/configuration/dotfiles/.tmux.conf
	    '';
    };
    chromium.enable = true;
    git = {
    	enable = true;
      package = pkgs.gitAndTools.gitFull;
      includes = [{ path = "/home/${username}/Workspace/configuration/dotfiles/.gitconfig"; }];
      lfs.enable = true;
    };
    # bash.enable = true;
    zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      oh-my-zsh = {
        enable = true;
        theme = "candy";
        plugins = [ "git" "ssh-agent" "docker" "docker-compose" "vagrant" "man" ];
        # extra config for plugins
        extraConfig = ''
          zstyle :omz:plugins:ssh-agent identities id_ed25519
          zstyle :omz:plugins:ssh-agent agent-forwarding on
          zstyle :omz:plugins:ssh-agent lifetime 24h
        '';
      };
      # extra config for zsh itself
      initExtra = builtins.readFile ./dotfiles/.zshrc;
    };
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withPython = true;
      withPython3 = true;
      withRuby = true;
      withNodeJs = true;
      configure.customRC = builtins.readFile ./dotfiles/.vimrc;
    };
    # eclipse = {
    #   enable = true;
    #   jvmArgs = [ "-Xmx2048m" ];
    #   plugins = with eclipses.plugins; [ cdt ];
    #   # plugins = [ "cdt" ];
    # };
  };
  # xsession.enable = true;
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };

  # home.stateVersion = "20.03";
}
