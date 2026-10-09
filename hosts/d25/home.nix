{
  config,
  lib,
  pkgs,
  pkgsUnstable,
  ...
}:

let
  idleDelay = 3600;
in
{
  imports = [
    ../home.nix
    (import ./gnome.nix { inherit idleDelay lib; })
  ];

  home = {
    # Keep host lifecycle versions local even while their current values match.
    stateVersion = "26.05";

    packages = [
      pkgs.zed-editor
      (pkgs.callPackage ./pkgs/trik-studio/package.nix { })
      (pkgs.callPackage ./pkgs/rotki.nix { })
    ];
  };

  programs.keepassxc.settings.Security.LockDatabaseIdleSeconds = idleDelay;

  # Replaces the entry Bitwarden writes itself, which points at the unwrapped
  # store path and bypasses the wrapper from ../home.nix.
  # Disable autostart until Bitwarden no longer blocks hibernation (memfd_secret).
  # Check before re-enabling: https://github.com/bitwarden/clients/issues/21661
  xdg.configFile."autostart/bitwarden.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Bitwarden
      Hidden=true
      Exec=${config.home.profileDirectory}/bin/bitwarden --autostart
      Icon=bitwarden
      Terminal=false
    '';
  };

  xdg.configFile."autostart/org.telegram.desktop.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Telegram
      Exec=${pkgsUnstable.telegram-desktop}/bin/Telegram -startintray
      Icon=org.telegram.desktop
      Terminal=false
      StartupWMClass=TelegramDesktop
    '';
  };
}
