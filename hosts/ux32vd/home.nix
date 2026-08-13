{
  config,
  lib,
  pkgs,
  pkgsUnstable,
  userName,
  ...
}:

{
  imports = [
    ./agents.nix
    ./goldendict.nix
    ./plasma.nix
    ./syncthing.nix
    ./vscode.nix
  ];

  home = {
    username = userName;
    homeDirectory = "/home/${userName}";
    stateVersion = "26.05";

    packages = with pkgs; [
      anki
      pkgsUnstable.bitwarden-desktop # Stable still depends on EOL Electron 39.
      brave
      element-desktop
      lmstudio
      ripgrep
      slack
      telegram-desktop
      wget
      xclip # Used by the `c` and `v` shell aliases.
      zulip
    ];

    activation.zulipStartMinimized =
      let
        commands = {
          install = lib.getExe' pkgs.coreutils "install";
          jq = lib.getExe pkgs.jq;
          mktemp = lib.getExe' pkgs.coreutils "mktemp";
          rm = lib.getExe' pkgs.coreutils "rm";
        };
        managedSettings = pkgs.writeText "zulip-managed-settings.json" (
          builtins.toJSON {
            startMinimized = true;
            trayIcon = true;
          }
        );
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        settings_file="${config.xdg.configHome}/Zulip/config/settings.json"

        if [[ -e "$settings_file" ]]; then
          settings_tmp="$(${commands.mktemp})"
          ${commands.jq} '.startMinimized = true | .trayIcon = true' "$settings_file" > "$settings_tmp"
          ${commands.install} -Dm600 "$settings_tmp" "$settings_file"
          ${commands.rm} -f "$settings_tmp"
        else
          ${commands.install} -Dm600 ${managedSettings} "$settings_file"
        fi
      '';
  };

  programs = {
    bash.enable = true;

    firefox = {
      enable = true;

      policies.ExtensionSettings."keepassxc-browser@keepassxc.org" = {
        installation_mode = "normal_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
      };
    };

    home-manager.enable = true;

    # programs.plasma is in plasma.nix.

    keepassxc = {
      enable = true;

      settings.Browser = {
        Enabled = true;
        UpdateBinaryPath = false;
      };
    };

    zsh = {
      enable = true;

      shellAliases = {
        c = "xclip -selection clipboard";
        v = "xclip -o";
      };

      oh-my-zsh = {
        enable = true;
        theme = "ys";
      };

      # Use VSCode as git editor when in its integrated terminal, nano otherwise.
      # Consider removing when migrated git config from a dotfile to nix.
      initContent = ''
        if [ "$TERM_PROGRAM" = "vscode" ]; then
          git config --global core.editor "code --wait"
        fi
      '';
    };

    # programs.vscode is in vscode.nix: the package is assembled there rather
    # than merely configured.
  };

  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      "text/html" = "brave-browser.desktop";
      "application/xhtml+xml" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/chromium" = "brave-browser.desktop";
      # kdePackages.kate ships both Kate and KWrite desktop files.
      "text/plain" = "org.kde.kwrite.desktop";
      "text/markdown" = "org.kde.kwrite.desktop";
    };
  };

  xdg.configFile =
    let
      autostart =
        {
          name,
          exec,
          icon,
          startupWMClass,
        }:
        {
          force = true;
          text = ''
            [Desktop Entry]
            Type=Application
            Name=${name}
            Exec=${exec}
            Icon=${icon}
            Terminal=false
            StartupWMClass=${startupWMClass}
          '';
        };
    in
    {
      "autostart/org.telegram.desktop.desktop" = autostart {
        name = "Telegram";
        exec = "${pkgs.telegram-desktop}/bin/Telegram -startintray";
        icon = "org.telegram.desktop";
        startupWMClass = "TelegramDesktop";
      };

      "autostart/element-desktop.desktop" = autostart {
        name = "Element";
        exec = "${pkgs.element-desktop}/bin/element-desktop --hidden";
        icon = "element";
        startupWMClass = "Element";
      };

      "autostart/zulip.desktop" = autostart {
        name = "Zulip";
        exec = "${pkgs.zulip}/bin/zulip";
        icon = "zulip";
        startupWMClass = "Zulip";
      };
    };
}
