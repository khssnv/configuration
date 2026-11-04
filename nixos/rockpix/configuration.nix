{ lib, pkgs, ... }:

let
  ap6255Firmware = pkgs.callPackage ./pkgs/ap6255-firmware.nix { };

  youtubeKiosk = pkgs.writeShellScript "youtube-kiosk" ''
    if [ "$USER" != "kiosk" ]; then
      exit 0
    fi

    exec ${lib.getExe pkgs.firefox} --kiosk https://www.youtube.com/
  '';
in
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "rockpix";
    networkmanager.enable = true;
  };

  time.timeZone = "Asia/Almaty";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_AU.UTF-8";
      LC_IDENTIFICATION = "en_AU.UTF-8";
      LC_MEASUREMENT = "en_AU.UTF-8";
      LC_MONETARY = "en_AU.UTF-8";
      LC_NAME = "en_AU.UTF-8";
      LC_NUMERIC = "en_AU.UTF-8";
      LC_PAPER = "en_AU.UTF-8";
      LC_TELEPHONE = "en_AU.UTF-8";
      LC_TIME = "en_AU.UTF-8";
    };
  };

  services = {
    displayManager.autoLogin = {
      enable = true;
      user = "kiosk";
    };

    xserver = {
      enable = true;
      xkb.layout = "us,ru";
    };

    displayManager.gdm = {
      enable = true;
      autoSuspend = false;
    };

    desktopManager.gnome = {
      enable = true;
      extraGSettingsOverrides = ''
        [org.gnome.desktop.session]
        idle-delay=0

        [org.gnome.settings-daemon.plugins.power]
        idle-dim=false
        sleep-inactive-ac-type='nothing'
        sleep-inactive-battery-type='nothing'

        [org.gnome.shell]
        enabled-extensions=['${pkgs.gnomeExtensions.no-overview.extensionUuid}']
      '';
      extraGSettingsOverridePackages = [ pkgs.gnome-settings-daemon ];
    };

    gnome = {
      core-apps.enable = false;
      gnome-initial-setup.enable = false;
    };

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    logind.settings.Login = {
      HandleSuspendKey = "ignore";
      HandleHibernateKey = "ignore";
      IdleAction = "ignore";
    };
  };

  # Reject sleep requests from every desktop and service, not only from GNOME.
  systemd.sleep.settings.Sleep = {
    AllowSuspend = false;
    AllowHibernation = false;
    AllowHybridSleep = false;
    AllowSuspendThenHibernate = false;
  };

  security.rtkit.enable = true;

  users.users =
    let
      sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLB7lnUc9iy4UYdAl5q2qmrB1VEuRMcucluAe6WFpYV a.khssnv@gmail.com";
    in
    {
      alisher = {
        isNormalUser = true;
        description = "Alisher Khassanov";
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        openssh.authorizedKeys.keys = [ sshPublicKey ];
      };

      kiosk = {
        isNormalUser = true;
        description = "Home kiosk";
      };

      root.openssh.authorizedKeys.keys = [ sshPublicKey ];
    };

  programs.firefox = {
    enable = true;
    preferences = {
      # Cherryview can decode H.264 in hardware, but not YouTube's VP9 or AV1.
      "media.av1.enabled" = false;
      "media.webm.enabled" = false;
    };
  };

  environment.etc."xdg/autostart/youtube-kiosk.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=YouTube kiosk
    Exec=${youtubeKiosk}
    OnlyShowIn=GNOME;
  '';

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
    pkgs.gnomeExtensions.no-overview
    pkgs.htop
    pkgs.lm_sensors
  ];

  hardware = {
    enableRedistributableFirmware = true;
    firmware = [ ap6255Firmware ];
    graphics.extraPackages = [ pkgs.intel-vaapi-driver ];
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "alisher" ];
  };

  nixpkgs.config.allowUnfree = true;

  zramSwap.enable = true;

  system.stateVersion = "26.05";
}
