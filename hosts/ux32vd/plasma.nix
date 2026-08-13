{
  pkgs,
  ...
}:

let
  kryptotrackPluginId = "com.github.i1mercep.kryptotrack";

  kryptotrack = pkgs.stdenvNoCC.mkDerivation {
    pname = "plasma-applet-kryptotrack";
    version = "1.3.1";

    src = pkgs.fetchurl {
      name = "kryptotrack-1.3.1.plasmoid";
      url = "https://api.opendesktop.org/ocs/v1/content/download/2297595/3";
      hash = "sha256-1qs7h5cI1DN2G3wM7/9XL5s9FmzIAagiKQYoZMbMyVI=";
      curlOptsList = [
        "--header"
        "Accept: application/json"
      ];
      postFetch = ''
        downloadUrl="$(${pkgs.jq}/bin/jq -er '.data[0].downloadlink' "$out")"
        ${pkgs.curl}/bin/curl --fail --location --retry 3 \
          "$downloadUrl" \
          --output "$TMPDIR/kryptotrack.plasmoid"
        mv "$TMPDIR/kryptotrack.plasmoid" "$out"
      '';
    };

    nativeBuildInputs = [ pkgs.unzip ];
    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      install -d "$out/share/plasma/plasmoids/${kryptotrackPluginId}"
      unzip -q "$src" -d "$out/share/plasma/plasmoids/${kryptotrackPluginId}"

      runHook postInstall
    '';

    meta = {
      description = "Plasma 6 applet for tracking cryptocurrency prices";
      homepage = "https://store.kde.org/p/2297595";
      license = pkgs.lib.licenses.gpl3Plus;
      platforms = pkgs.lib.platforms.linux;
    };
  };

  kryptotrackWidget = {
    name = kryptotrackPluginId;
    config = {
      General = {
        coin = "bitcoin";
        coinSymbol = "btc";
        baseCurrency = "usd";
        refreshInterval = 60;
      };
      API = {
        apiProvider = "coingecko";
        timeout = 5;
      };
      Appearance.displayBaseCurrency = true;
    };
  };

  togglePrimaryKeyboardLayouts = pkgs.writeShellScript "toggle-primary-keyboard-layouts" ''
    set -eu

    current="$(${pkgs.systemd}/bin/busctl --user call org.kde.keyboard /Layouts org.kde.KeyboardLayouts getLayout)"
    case "$current" in
      "u 0") target=1 ;;
      *) target=0 ;;
    esac

    exec ${pkgs.systemd}/bin/busctl --user call org.kde.keyboard /Layouts org.kde.KeyboardLayouts setLayout u "$target"
  '';

  appLaunchers = [
    "applications:org.kde.konsole.desktop"
    "applications:brave-browser.desktop"
    # System Settings' Default Applications has a Text Editor category, but the
    # panel's preferred:// launcher URLs only resolve "browser" and
    # "filemanager" (hardcoded in libtaskmanager), so KWrite is pinned directly.
    "applications:org.kde.kwrite.desktop"
    "applications:code.desktop"
    "applications:org.telegram.desktop.desktop"
    "applications:zulip.desktop"
    "preferred://filemanager"
    "applications:org.keepassxc.KeePassXC.desktop"
    "applications:bitwarden.desktop"
    "applications:anki.desktop"
  ];

  systemMonitor = sensorIds: {
    systemMonitor = {
      displayStyle = "org.kde.ksysguard.linechart";

      settings = {
        Sensors.highPrioritySensorIds = builtins.toJSON sensorIds;
        "org.kde.ksysguard.linechart/General".historyAmount = 30;
      };
    };
  };

  systemMonitors = [
    (systemMonitor [ "cpu/all/usage" ])
    (systemMonitor [ "cpu/all/maximumTemperature" ])
    (systemMonitor [ "memory/physical/used" ])
    (systemMonitor [
      "network/all/download"
      "network/all/upload"
    ])
  ];

  systemTrayItems = {
    # runAlways bypasses Plasma's one-time defaults. After Plasma upgrades,
    # verify KPlugin.EnabledByDefault in installed metadata:
    # `qtplugininfo /run/current-system/sw/lib/qt-6/plugins/plasma/applets/*.so`
    # and `/run/current-system/sw/share/plasma/plasmoids/*/metadata.json`.
    extra = [
      "org.kde.kdeconnect"
      "org.kde.kscreen"
      "org.kde.plasma.battery"
      "org.kde.plasma.brightness"
      "org.kde.plasma.cameraindicator"
      "org.kde.plasma.clipboard"
      "org.kde.plasma.devicenotifier"
      "org.kde.plasma.keyboardindicator"
      "org.kde.plasma.keyboardlayout"
      "org.kde.plasma.manage-inputmethod"
      "org.kde.plasma.mediacontroller"
      "org.kde.plasma.networkmanagement"
      "org.kde.plasma.notifications"
      "org.kde.plasma.printmanager"
      "org.kde.plasma.volume"
      "org.kde.plasma.weather"
      # Installed by syncthing.nix and disabled by default upstream.
      "martchus.syncthingplasmoid"
    ];
    shown = [
      "org.kde.kdeconnect"
      "org.kde.plasma.battery"
      "org.kde.plasma.brightness"
      "org.kde.plasma.clipboard"
      "org.kde.plasma.keyboardlayout"
      "org.kde.plasma.networkmanagement"
      "org.kde.plasma.notifications"
      "org.kde.plasma.volume"
      "martchus.syncthingplasmoid"
    ];
  };

  configuredPanels = [
    {
      location = "top";
      height = 28;
      widgets = [
        {
          kickoff = {
            icon = "start-here-symbolic";
            sortAlphabetically = true;
            compactDisplayStyle = true;
          };
        }
        "org.kde.plasma.pager"
        {
          appMenu.compactView = true;
        }
      ]
      ++ systemMonitors
      ++ [
        {
          panelSpacer.expanding = true;
        }
        {
          digitalClock = {
            date = {
              enable = true;
              format = {
                custom = "ddd d MMM";
              };
              position = "besideTime";
            };
            time = {
              format = "24h";
              showSeconds = "never";
            };
          };
        }
        {
          panelSpacer.expanding = true;
        }
        kryptotrackWidget
        {
          systemTray = {
            icons.spacing = "small";
            items = systemTrayItems;
          };
        }
      ];
    }
    {
      location = "left";
      height = 56;
      widgets = [
        {
          iconTasks = {
            launchers = appLaunchers;
            appearance = {
              fill = false;
              iconSpacing = "medium";
            };
            behavior = {
              grouping.method = "byProgramName";
              sortingMethod = "manually";
            };
          };
        }
      ];
    }
  ];
in

{
  home.packages = [
    kryptotrack
    pkgs.kdePackages.kate
    pkgs.kdePackages.ktorrent
  ];

  programs.plasma = {
    enable = true;

    # Ensure every rebuild reverts manual panel changes.
    startup.desktopScript.panels.runAlways = true;

    # Switch the global theme between light and dark around real
    # sunrise/sunset (System Settings > Appearance > Global Theme >
    # Theme Mode > Automatic). No typed plasma-manager option exists yet
    # for this KDE 6.5+ feature, see nix-community/plasma-manager#562.
    configFile."kdeglobals"."KDE"."AutomaticLookAndFeel" = true;

    # Reduce visual overhead on older hardware.
    configFile."kdeglobals"."KDE"."AnimationDurationFactor" = 0;
    configFile."kwinrc"."Plugins"."blurEnabled" = false;
    configFile."kwinrc"."Plugins"."contrastEnabled" = false;
    configFile."kwinrc"."Plugins"."fadingpopupsEnabled" = false;
    configFile."kwinrc"."Plugins"."fullscreenEnabled" = false;
    configFile."kwinrc"."Plugins"."maximizeEnabled" = false;
    configFile."kwinrc"."Plugins"."scaleEnabled" = false;
    configFile."kwinrc"."Plugins"."slidingpopupsEnabled" = false;
    configFile."kwinrc"."Plugins"."squashEnabled" = false;
    configFile."kwinrc"."Plugins"."translucencyEnabled" = false;
    configFile."kwinrc"."Plugins"."windowapertureEnabled" = false;

    # Keep other status OSDs, but hide the popup on keyboard layout changes.
    configFile."plasmarc"."OSD"."kbdLayoutChangedEnabled" = false;

    input.keyboard.layouts = [
      { layout = "us"; }
      { layout = "ru"; }
      { layout = "kz"; }
    ];

    # Keep Kazakh selectable through the panel, while Meta+Space toggles only
    # English/Russian through the DBus command below.
    shortcuts."KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = [ ];

    hotkeys.commands.switch-english-russian-keyboard-layout = {
      name = "Switch English/Russian Keyboard Layout";
      comment = "Switch English/Russian Keyboard Layout";
      key = "Meta+Space";
      command = "${togglePrimaryKeyboardLayouts}";
      logs.enabled = false;
    };

    session.sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";

    window-rules = [
      {
        description = "Start Bitwarden minimized";
        match = {
          window-class = {
            value = "bitwarden";
            type = "substring";
            match-whole = false;
          };
          window-types = [ "normal" ];
        };
        apply.minimize = true;
      }
      {
        description = "Start Telegram minimized";
        match = {
          window-class = {
            value = "telegram";
            type = "substring";
            match-whole = false;
          };
          window-types = [ "normal" ];
        };
        apply.minimize = true;
      }
    ];

    # Never lock the screen: neither on idle timeout nor on resume from
    # sleep. Manual locking (Ctrl+Alt+L) still works.
    kscreenlocker = {
      autoLock = false;
      lockOnResume = false;
    };

    # Lid and power button behaviour lives in power.nix, together with the
    # logind and acpid halves of the same feature.

    panels = configuredPanels;
  };
}
