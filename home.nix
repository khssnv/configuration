{ config, pkgs, ... }:

let
  username = "khassanov";

in
{
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
  programs.home-manager.enable = true;
  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    # pianoteq
    # wineWowPackages.staging
    # nodePackages.tern # wanted by emacs ts layer, but fail HM
    # nodePackages.prettier

    # tree # fails home-manager service
    # python38Packages.ipython
    (vagrant.override { withLibvirt = false; }) # temporary fix for xen issue
    alacritty
    anydesk
    awscli2
    bmon # network usage monitor
    brave
    coreutils
    discord
    docker
    docker-compose
    eclipses.eclipse-cpp
    element-desktop # matrix messaging
    evince
    firefox
    gimp
    go-tools
    go_bootstrap
    goimports
    goldendict # dictionary lookup
    gotools
    htop
    hubstaff
    jetbrains.idea-ultimate
    kompose
    kubectl
    kubernetes
    kubernetes-helm
    ledger-live-desktop
    libreoffice
    minikube
    mongodb-compass
    ncdu # disk usage
    nodejs
    nvtop # htop-like monitoring tool for GPU
    obs-studio
    openshot-qt
    openssl
    opera
    pavucontrol
    pciutils
    pipenv
    postman
    python38Packages.pip
    qalculate-gtk
    qemu
    skype
    slack
    spotify
    steam
    tdesktop # telegram
    teamviewer
    termdown
    transmission-gtk # torrents
    umlet
    unrar
    viber
    virt-manager # qemu GUI
    vlc
    vokoscreen-ng
    wmctrl # X Window manager cli
    xclip
    yarn
    zoom-us
  ];
  programs = {
    command-not-found.enable = true;
    git = {
      enable = true;
      package = pkgs.gitAndTools.gitFull;
      includes = [{ path = "/home/${username}/Workspace/configuration/dotfiles/.gitconfig"; }];
      lfs.enable = true;
    };
    chromium.enable = true;
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withNodeJs = true;
      withPython = true;
      withPython3 = true;
      withRuby = true;
      plugins = with pkgs.vimPlugins; [
        # vim-graphql
        # vim-ros
        # vim-scheme
        # vim-urscript
        YouCompleteMe
        fzf-vim
        indentLine
        jellybeans-vim
        nerdtree
        tagbar
        vim-fugitive
        vim-gitgutter
        vim-go
        vim-gutentags
        vim-json
        vim-nix
        vim-toml
        vim-xkbswitch
        vimspector
      ];
      extraConfig = builtins.readFile ./dotfiles/.vimrc;
      extraPackages = with pkgs; [
        clang-tools # required by coc-nvim for C-family
        rust-analyzer
        universal-ctags
        xkb-switch # required by vim-xkbswitch
      ];
      # extraPython3Packages = (ps: with ps; [
      #   pyls-black # required by coc-nvim
      #   pyls-isort # required by coc-nvim
      #   pyls-mypy # required by coc-nvim
      # ]);
    };
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
    # eclipse = {
    #   enable = true;
    #   jvmArgs = [ "-Xmx2048m" ];
    #   plugins = with eclipses.plugins; [ cdt ];
    #   # plugins = [ "cdt" ];
    # };
    # rofi.enable = true;
  };
  # xsession = {
  #   enable = true;
  #   windowManager.xmonad = {
  #     enable = true;
  #     enableContribAndExtras = true;
  #     extraPackages = haskellPackages: [
  #       haskellPackages.xmonad-contrib
  #       haskellPackages.xmonad-extras
  #       haskellPackages.xmonad
  #       haskellPackages.monad-logger
  #     ];
  #     config = ./dotfiles/.xmonad/xmonad.hs;
  #   };
  # };
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };
  home.stateVersion = "20.09";

  services.emacs = {
    enable = true; # emacs daemon mode
    client.enable = true; # desktop icon
  };
  programs.emacs = {
    enable = true;
    # extraPackages = epkgs: [
    #   # epkgs.pdf-tools # never works as expected
    #   # nodePckages.tern
    #   # pkgs.gocode
    #   # pkgs.gocode-gomod
    #   # epkgs.go-guru
    #   # pkgs.goimports
    #   # pkgs.go_bootstrap
    #   # pkgs.goimports
    #   # pkgs.node
    # ];
  };
  home.file.".emacs.d" = {
    source = builtins.fetchGit {
      url = "https://github.com/syl20bnr/spacemacs";
      ref = "develop";
    };
    recursive = true;
  };
  home.file.".spacemacs".source = ./dotfiles/.spacemacs.el;
  home.file."./.config/alacritty/alacritty.yml".source = ./dotfiles/alacritty.yml;
  home.file.".ideavimrc".source = ./dotfiles/.ideavimrc;
}
