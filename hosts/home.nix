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
    ./gnome.nix
    ./goldendict.nix
    ./syncthing.nix
    ./vscode.nix
  ];

  home = {
    username = userName;
    homeDirectory = "/home/${userName}";
    file.".gitconfig".source = ../dotfiles/.gitconfig;

    sessionVariables.GIT_EDITOR = pkgs.writeShellScript "git-editor" ''
      if [[ "''${TERM_PROGRAM:-}" == "vscode" ]]; then
        exec ${lib.getExe config.programs.vscode.package} --wait "$@"
      else
        exec ${lib.getExe pkgs.nano} "$@"
      fi
    '';

    packages = with pkgs; [
      anki
      (
        let
          # Bitwarden 2026.7.0 cannot access the clipboard through GNOME's Wayland
          # portal. Run only Bitwarden through XWayland until the upstream fix ships.
          bitwarden = pkgs.symlinkJoin {
            name = "bitwarden-desktop-x11";
            paths = [ pkgsUnstable.bitwarden-desktop ]; # Stable still depends on EOL Electron 39.
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/bitwarden \
                --unset WAYLAND_DISPLAY \
                --unset XDG_CURRENT_DESKTOP \
                --set ELECTRON_OZONE_PLATFORM_HINT x11
            '';
          };
        in
        bitwarden
      )
      element-desktop
      git
      gnome-boxes
      just
      lmstudio
      papers
      remmina
      ripgrep
      slack
      telegram-desktop
      transmission_4-gtk
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

    brave.enable = true;

    firefox = {
      enable = true;

      policies.ExtensionSettings."keepassxc-browser@keepassxc.org" = {
        installation_mode = "normal_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
      };
    };

    home-manager.enable = true;

    keepassxc = {
      enable = true;
      package = pkgs.symlinkJoin {
        name = "keepassxc-with-chromium-native-messaging-host";
        paths = [
          pkgs.keepassxc
          (pkgs.writeTextDir "etc/chromium/native-messaging-hosts/org.keepassxc.keepassxc_browser.json" (
            builtins.toJSON {
              name = "org.keepassxc.keepassxc_browser";
              description = "KeePassXC integration with native messaging support";
              path = lib.getExe' pkgs.keepassxc "keepassxc-proxy";
              type = "stdio";
              allowed_origins = [ "chrome-extension://oboonakemofpalcgghocfoadofidjkkk/" ];
            }
          ))
        ];
        meta.mainProgram = "keepassxc";
      };

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
      "text/plain" = "org.gnome.TextEditor.desktop";
      "text/markdown" = "org.gnome.TextEditor.desktop";
    };
  };

  home.file."${config.xdg.configHome}/BraveSoftware/Brave-Browser/NativeMessagingHosts".force = true;

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
      "autostart/org.keepassxc.KeePassXC.desktop" = autostart {
        name = "KeePassXC";
        exec = pkgs.writeShellScript "keepassxc-autostart" ''
          # Let GNOME apply the monitor layout and fractional scale before Qt
          # determines KeePassXC's initial screen DPI.
          ${lib.getExe' pkgs.coreutils "sleep"} 5
          exec ${lib.getExe config.programs.keepassxc.package} --minimized
        '';
        icon = "keepassxc";
        startupWMClass = "keepassxc";
      };

      "autostart/org.telegram.desktop.desktop" = autostart {
        name = "Telegram";
        exec = "${pkgs.telegram-desktop}/bin/Telegram -startintray";
        icon = "org.telegram.desktop";
        startupWMClass = "TelegramDesktop";
      };
    };
}
