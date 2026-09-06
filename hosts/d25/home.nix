{ lib, pkgs, ... }:

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

    packages = [ pkgs.zed-editor ];
  };

  programs.keepassxc.settings.Security.LockDatabaseIdleSeconds = idleDelay;

  xdg.configFile."autostart/org.telegram.desktop.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Telegram
      Exec=${pkgs.telegram-desktop}/bin/Telegram -startintray
      Icon=org.telegram.desktop
      Terminal=false
      StartupWMClass=TelegramDesktop
    '';
  };
}
