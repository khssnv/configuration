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
    # tree # fails home-manager service
    # wineWowPackages.staging
    goimports
    go_bootstrap
    go-tools
    gotools
    nodejs
    hubstaff
    # nodePackages.tern # wanted by emacs ts layer, but fail HM
    # nodePackages.prettier

    alacritty
    anydesk
    bmon # network usage monitor
    coreutils
    discord
    docker
    docker-compose
    element-desktop # matrix messaging
    evince
    gimp
    goldendict # dictionary lookup
    htop
    ledger-live-desktop
    libreoffice
    mongodb-compass
    ncdu # disk usage
    nvtop # htop-like monitoring tool for GPU
    obs-studio
    # openshot-qt
    opera
    pavucontrol
    pciutils
    pipenv
    python3Packages.ipython
    python3Packages.pip
    qalculate-gtk
    qemu
    skype
    slack
    spotify
    steam
    tdesktop # telegram
    teamviewer
    transmission-gtk
    umlet
    unrar
    vagrant
    vlc
    vokoscreen
    wmctrl # X Window manager cli
    xclip
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
        jellybeans-vim
        nerdtree
        tagbar
        vim-gitgutter
        vim-fugitive
        vim-go
        vim-gutentags
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

  services.emacs.enable = true; # emacs daemon mode
  programs.emacs = {
    enable = true;
    extraPackages = epkgs: [
      # epkgs.pdf-tools # never works as expected
      # nodePckages.tern
      # pkgs.gocode
      # pkgs.gocode-gomod
      # epkgs.go-guru
      # pkgs.goimports
      # pkgs.go_bootstrap
      # pkgs.goimports
    ];
  };
  home.file.".emacs.d" = {
    source = builtins.fetchGit {
      url = "https://github.com/syl20bnr/spacemacs";
      ref = "develop";
    };
    recursive = true;
  };
  home.file.".spacemacs".source = ./dotfiles/.spacemacs.el;
  # spacemacs goes manually now
  # git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
  # home.file.".emacs.d" = {
  #   # don't make the directory read only so that impure melpa can still happen
  #   # for now
  #   recursive = true;
  #   # source = pkgs.fetchFromGitHub {
  #   #   owner = "syl20bnr";
  #   #   repo = "spacemacs";
  #   #   rev = "d46eacd83842815b24afcb2e1fee5c80c38187c5";
  #   #   sha256 = "1r8q7bnszkrxh4q9l78n6xgxflpc52hcd18d3n9kc5r8xma20387";
  #   # };
  #   source = builtins.fetchGit {
  #     url = "https://github.com/syl20bnr/spacemacs";
  #     ref = "master";
  #   };
  # };
  # home.file.".spacemacs".source = ./dotfiles/.spacemacs.el;
}
