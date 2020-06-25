{ config, pkgs, ... }:

{
  imports =
    [
      <home-manager/nixos>
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.useOSProber = true;
  boot.supportedFilesystems = [ "ntfs" ];

  networking.hostName = "ux32vd";
  networking.networkmanager.enable = true;

  networking.interfaces.wlp3s0.useDHCP = true;

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  time.timeZone = "Europe/Barcelona";

  # environment.systemPackages = with pkgs; [
  #   wget
  # ];

  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "qt";
  };

  # services.openssh.enable = true;

  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  networking.firewall.enable = false;

  # services.printing.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "eurosign:e";

  services.xserver.videoDrivers = [ "modesetting" "nvidia" ];
  hardware.nvidia.prime = {
    sync.enable = true;
    nvidiaBusId = "PCI:1:0:0";
    intelBusId = "PCI:0:2:0";
  };

  # Enable touchpad support.
  services.xserver.libinput.enable = true;

  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  nixpkgs.config.allowUnfree = true;

  users.users.khassanov = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/khassanov";
    description = "Alisher A. Khassanov";
    extraGroups = [ "wheel" "networkmanager" ];
  };

  home-manager.users.khassanov = { pkgs, ... }: {
    home.packages = with pkgs; [ 
      ark # KDE archive manager
      gparted
      htop
      ncdu # disk usage
    ];
    programs = {
      tmux = {
        enable = true;
        extraConfig = ''
	        source /home/khassanov/Workspace/configuration/dotfiles/.tmux.conf
	      '';
      };
      chromium.enable = true;
      git = {
      	enable = true;
        includes = [{ path = "/home/khassanov/.gitconfig"; }];
      };
      bash.enable = true;
      neovim = {
        enable = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        withPython = true;
        withPython3 = true;
        withRuby = true;
        withNodeJs = true;
        configure.customRC = ''
          if filereadable($HOME . "/.vimrc")
            source ~/.vimrc
          endif
        '';
      };
    };
    # xsession.enable = true;
    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
    };
  };

  system.stateVersion = "20.03";

}

