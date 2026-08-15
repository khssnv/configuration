{
  pkgs,
  userName,
  ...
}:

{
  imports = [ ./shares.nix ];

  zramSwap.enable = true;

  networking.networkmanager = {
    enable = true;
    plugins = [ pkgs.networkmanager-openvpn ];
  };

  services.xserver = {
    enable = true;
    xkb.layout = "us,ru,kz";
  };

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # GSConnect implements KDE Connect protocol for GNOME. This NixOS option
  # installs the extension and opens the protocol ports in the firewall.
  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };

  time.timeZone = "Asia/Almaty";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
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

  fonts = {
    packages = [ pkgs.jetbrains-mono ];

    fontconfig.defaultFonts.monospace = [ "JetBrains Mono" ];
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.${userName} = {
    isNormalUser = true;
    description = "Alisher Khassanov";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  programs.zsh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.systemPackages = with pkgs; [
    vim
    curl
  ];

  services.openssh.enable = true;
}
