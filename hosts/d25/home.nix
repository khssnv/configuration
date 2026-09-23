{
  config,
  lib,
  pkgs,
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

    packages = [ pkgs.zed-editor ];
  };

  programs.keepassxc.settings.Security.LockDatabaseIdleSeconds = idleDelay;

  # Replaces the entry Bitwarden writes itself, which points at the unwrapped
  # store path and bypasses the wrapper from ../home.nix.
  xdg.configFile."autostart/bitwarden.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Bitwarden
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
      Exec=${pkgs.telegram-desktop}/bin/Telegram -startintray
      Icon=org.telegram.desktop
      Terminal=false
      StartupWMClass=TelegramDesktop
    '';
  };
}
