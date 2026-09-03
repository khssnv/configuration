{
  hostName,
  lib,
  pkgs,
  ...
}:

let
  gtkBookmarks = ''
    file:///mnt/truenas/shared-ssd ssd@truenas.lan
    file:///mnt/truenas/shared-hdd hdd@truenas.lan
    file:///mnt/truenas/transmission transmission@truenas.lan
  '';
in
{
  imports = [ ./wallpaper.nix ];

  home.packages = with pkgs; [
    deja-dup
    gnome-tweaks
    gnomeExtensions.appindicator
    gnomeExtensions.caffeine
    gnomeExtensions.dash-to-dock
    gnomeExtensions.night-theme-switcher
    gnomeExtensions.no-overview
    gnomeExtensions.system-monitor-next
    gnomeExtensions.user-themes
    yaru-theme
  ];

  dconf = {
    enable = true;

    settings = {
      "org/gnome/DejaDup" = {
        backend = "local";
        include-list = [ "$HOME" ];
        exclude-list = [
          "$TRASH"
          "$DOWNLOAD"
        ];
        periodic = false;
      };

      "org/gnome/DejaDup/Local".folder = "/mnt/truenas/shared-hdd/Alisher/Backups/${hostName}";

      "org/gnome/desktop/input-sources" = {
        sources = [
          (lib.hm.gvariant.mkTuple [
            "xkb"
            "us"
          ])
          (lib.hm.gvariant.mkTuple [
            "xkb"
            "ru"
          ])
          (lib.hm.gvariant.mkTuple [
            "xkb"
            "kz"
          ])
        ];
      };

      "org/gnome/desktop/calendar".show-weekdate = true;

      "org/gnome/desktop/interface" = {
        accent-color = "orange";
        clock-format = "24h";
        clock-show-date = true;
        clock-show-weekday = true;
        cursor-theme = "Yaru";
        enable-hot-corners = false;
        gtk-theme = "Yaru";
        icon-theme = "Yaru";
        monospace-font-name = "JetBrains Mono 11";
        show-battery-percentage = true;
      };

      # Night Theme Switcher uses GeoClue to calculate local sunrise and
      # sunset, then updates the standard GNOME color-scheme preference.
      "org/gnome/system/location".enabled = true;

      "org/gnome/mutter" = {
        experimental-features = [ "scale-monitor-framebuffer" ];
        workspaces-only-on-primary = true;
      };

      # Disable automatic locking, including after resume. Manual locking stays
      # available from GNOME's system menu.
      "org/gnome/desktop/screensaver".lock-enabled = false;

      "org/gnome/desktop/wm/preferences".button-layout = ":minimize,maximize,close";

      "org/gnome/desktop/wm/keybindings" = {
        switch-input-source = [ "<Super>space" ];
        switch-input-source-backward = [ "<Shift><Super>space" ];
      };

      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [
          pkgs.gnomeExtensions.appindicator.extensionUuid
          pkgs.gnomeExtensions.caffeine.extensionUuid
          pkgs.gnomeExtensions.dash-to-dock.extensionUuid
          pkgs.gnomeExtensions.gsconnect.extensionUuid
          pkgs.gnomeExtensions.night-theme-switcher.extensionUuid
          pkgs.gnomeExtensions.no-overview.extensionUuid
          pkgs.gnomeExtensions.system-monitor-next.extensionUuid
          pkgs.gnomeExtensions.user-themes.extensionUuid
        ];
        favorite-apps = [
          "org.gnome.Console.desktop"
          "brave-browser.desktop"
          "org.gnome.TextEditor.desktop"
          "code.desktop"
          "org.telegram.desktop.desktop"
          "zulip.desktop"
          "org.gnome.Nautilus.desktop"
          "org.keepassxc.KeePassXC.desktop"
          "bitwarden.desktop"
          "anki.desktop"
          "org.gnome.Papers.desktop"
          "org.gnome.Settings.desktop"
        ];
      };

      "org/gnome/shell/extensions/dash-to-dock" = {
        autohide = false;
        background-color = "#131313";
        background-opacity = 0.975;
        custom-background-color = true;
        custom-theme-shrink = true;
        dash-max-icon-size = 36;
        dock-fixed = true;
        dock-position = "LEFT";
        extend-height = true;
        intellihide = false;
        running-indicator-style = "DOTS";
        show-mounts = false;
        show-trash = false;
        transparency-mode = "FIXED";
      };

      "org/gnome/shell/extensions/appindicator".tray-pos = "left";

      "org/gnome/shell/extensions/system-monitor-next-applet" = {
        icon-display = false;
        center-display = false;
        left-display = false;
        compact-display = false;

        cpu-display = true;
        cpu-graph-width = 45;
        cpu-position = 0;
        cpu-style = "graph";
        cpu-show-text = false;

        thermal-display = false;
        thermal-position = 1;
        thermal-sensor-label = "coretemp - Package id 0";
        thermal-show-menu = true;

        memory-display = true;
        memory-graph-width = 45;
        memory-position = 2;
        memory-style = "graph";
        memory-show-text = false;

        net-display = true;
        net-graph-width = 45;
        net-position = 3;
        net-style = "graph";
        net-show-text = false;
      };

      "org/gnome/shell/extensions/user-theme".name = "Yaru";
    };
  };

  xdg.configFile = {
    "gtk-3.0/bookmarks".text = gtkBookmarks;
    "gtk-4.0/bookmarks".text = gtkBookmarks;
  };
}
