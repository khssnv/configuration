# Syncthing runs as a user service after login.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  keepassxcPath = "Documents/Secrets/KeePassXC";
  relayId = "NG7SSGM-437H2EG-PKE5C4C-RELJWMC-6JPIQPC-3KREKST-7APKFTC-NRETUAB";
  relayToken = "change-me";
  relayUrl = "relay://2.vpsza500.khassanov.xyz:22067/?id=${relayId}&token=${relayToken}";

  bootstrapSyncthingTray = pkgs.writeShellApplication {
    name = "bootstrap-syncthingtray";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.crudini
      pkgs.libxml2
    ];
    text = ''
      config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
      settings_file="$config_home/syncthingtray.ini"

      # Same lookup as the home-manager Syncthing module: the state directory
      # wins, the legacy config directory is the fallback.
      syncthing_config="''${XDG_STATE_HOME:-$HOME/.local/state}/syncthing/config.xml"
      legacy_config="$config_home/syncthing/config.xml"
      if [[ ! -e "$syncthing_config" && -e "$legacy_config" ]]; then
        syncthing_config="$legacy_config"
      fi

      if ! api_key="$(xmllint --xpath 'string(configuration/gui/apikey)' "$syncthing_config" 2>/dev/null)" \
        || [[ -z "$api_key" ]]; then
        echo "No Syncthing API key in $syncthing_config." >&2
        echo "Start Syncthing once, then run this command again." >&2
        exit 1
      fi

      # The API key is a secret, so keep a newly created file private.
      umask 077
      mkdir -p "$config_home"

      # Syncthing Tray shows its setup wizard until the settings hold a
      # connection. Only the primary connection is managed here, other keys and
      # additional connections stay untouched.
      if ! crudini --get "$settings_file" tray 'connections\size' &>/dev/null; then
        crudini --set "$settings_file" tray 'connections\size' 1
      fi
      crudini --set "$settings_file" tray 'connections\1\syncthingUrl' "http://${config.services.syncthing.guiAddress}"
      crudini --set "$settings_file" tray 'connections\1\apiKey' "@ByteArray($api_key)"
      crudini --set "$settings_file" tray 'connections\1\autoConnect' true

      echo "Syncthing Tray connection written to $settings_file."
      echo "Start Syncthing Tray again to apply it."
    '';
  };
in
{
  # Syncthing refuses a symlinked .stignore, so copy a regular file instead of
  # managing it with home.file.
  home.activation.installSyncthingIgnore = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${lib.getExe' pkgs.coreutils "install"} -Dm644 ${../dotfiles/.stignore} "$HOME/${keepassxcPath}/.stignore"
  '';

  home.packages = [
    bootstrapSyncthingTray
    pkgs.syncthingtray
  ];

  xdg.configFile."autostart/syncthingtray.desktop" = {
    force = true;
    source = "${pkgs.syncthingtray}/share/applications/syncthingtray.desktop";
  };

  services.syncthing = {
    enable = true;

    settings = {
      devices.truenas = {
        id = "M5SSSMH-PPOUKC6-BJDJGK3-GBVAPKD-MTCSSJL-YPIDJSA-353WMNO-CP27FA5";
        addresses = [
          "tcp://truenas.lan:22000"
          relayUrl
        ];
      };

      folders = {
        "KeePassXC" = rec {
          label = path;
          path = "~/${keepassxcPath}";
          devices = [ "truenas" ];
        };
      };

      options = {
        globalAnnounceEnabled = false;
        listenAddresses = [
          "tcp4://:22000"
          "quic4://:22000"
          relayUrl
        ];
        localAnnounceEnabled = false;
        natEnabled = false;
        relaysEnabled = true;
      };
    };
  };
}
