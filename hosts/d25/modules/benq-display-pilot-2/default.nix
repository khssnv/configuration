# Autostart notes:
# - Attempt 1: XWayland + xdotool. Failed: visible tiny window.
# - Attempt 2: GNOME Shell workspace-d-bus minimize. Failed: still visible.
# - Attempt 3/current: click the native "Minimize Display Pilot 2" tray
#   menu item through StatusNotifierItem/dbusmenu. Works, but only after a
#   brief window flash.
{
  config,
  lib,
  pkgs,
  userName,
  ...
}:

let
  cfg = config.services.benqDisplayPilot2;
  defaultPackage = pkgs.callPackage ../../pkgs/benq-display-pilot-2.nix { };
  benqDisplayPilot2 = cfg.package;

  displayPilot2MinimizeFromTray = pkgs.writers.writePython3 "display-pilot-2-minimize-from-tray" {
    libraries = [ pkgs.python3Packages.dbus-python ];
  } (builtins.readFile ./minimize-from-tray.py);

  displayPilot2Autostart = pkgs.writeShellApplication {
    name = "display-pilot-2-autostart";
    runtimeInputs = [
      benqDisplayPilot2
      pkgs.coreutils
    ];
    text = ''
      (
        for _ in {1..150}; do
          ${displayPilot2MinimizeFromTray} >/dev/null 2>&1 && exit 0
          sleep 0.2
        done
      ) &

      exec benq-display-pilot-2
    '';
  };

  displayPilot2AutostartDesktop = pkgs.makeDesktopItem {
    name = "com.benq.DisplayPilot2";
    desktopName = "Display Pilot 2";
    exec = lib.getExe displayPilot2Autostart;
    icon = "dp2_svg";
    categories = [ "Utility" ];
    startupWMClass = "Display Pilot 2";
    extraConfig."X-GNOME-UsesNotifications" = "true";
  };

  autostartDesktopFile =
    if cfg.autostart.startMinimizedToTray then
      "${displayPilot2AutostartDesktop}/share/applications/com.benq.DisplayPilot2.desktop"
    else
      "${benqDisplayPilot2}/share/applications/com.benq.DisplayPilot2.desktop";
in

{
  options.services.benqDisplayPilot2 = {
    enable = lib.mkEnableOption "BenQ Display Pilot 2 monitor control integration";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultPackage;
      defaultText = "pkgs.callPackage ../../pkgs/benq-display-pilot-2.nix { }";
      description = "BenQ Display Pilot 2 package to install.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = userName;
      description = "User account that receives the Home Manager desktop integration.";
    };

    autostart = {
      enable = lib.mkEnableOption "Display Pilot 2 desktop autostart";

      startMinimizedToTray = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Start Display Pilot 2 and click its native tray-menu minimize action
          as soon as the StatusNotifierItem menu is available.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.i2c.enable = true;

    users.users.${cfg.user}.extraGroups = [ "i2c" ];

    home-manager.users.${cfg.user} = {
      home.packages = [ benqDisplayPilot2 ];

      xdg.configFile = lib.mkIf cfg.autostart.enable {
        "autostart/com.benq.DisplayPilot2.desktop".source = autostartDesktopFile;
      };
    };
  };
}
