# Syncthing runs as a user service after login.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.syncthing;

  keepassxcPath = "Documents/Secrets/KeePassXC";
  relayId = "U6LTZ5Z-MN4UMM2-YD5UHCR-BTZ6EFN-4JTJP7F-3OCCE5K-WVV3JSU-FS5C7AZ";
  relayAddress = "relay://2.vpsza500.khassanov.xyz:22067/?id=${relayId}";

  # The relay token is a secret, but home-manager passes the declared settings
  # through the Nix store. Append the relay address with the token over the
  # REST API instead, reading the token from the sops secret at runtime.
  addRelayAddress = pkgs.writeShellApplication {
    name = "syncthing-add-relay-address";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
      pkgs.libxml2
    ];
    text = ''
      # Same lookup as the home-manager Syncthing module: the state directory
      # wins, the legacy config directory is the fallback.
      syncthing_config="''${XDG_STATE_HOME:-$HOME/.local/state}/syncthing/config.xml"
      legacy_config="''${XDG_CONFIG_HOME:-$HOME/.config}/syncthing/config.xml"
      if [[ ! -e "$syncthing_config" && -e "$legacy_config" ]]; then
        syncthing_config="$legacy_config"
      fi

      # Pass the API key and the token through files and pipes only, so they
      # do not show up in process listings.
      umask 077
      headers="$RUNTIME_DIRECTORY/relay-headers"
      if ! api_key="$(xmllint --xpath 'string(configuration/gui/apikey)' "$syncthing_config" 2>/dev/null)" \
        || [[ -z "$api_key" ]]; then
        echo "No Syncthing API key in $syncthing_config." >&2
        echo "Start Syncthing once, then restart syncthing-init.service." >&2
        exit 1
      fi
      printf 'X-API-Key: %s\n' "$api_key" >"$headers"
      unset api_key

      token_file=${lib.escapeShellArg config.sops.secrets."syncthing-relay/token".path}
      token="$(<"$token_file")"
      if [[ ! "$token" =~ ^[0-9a-f]{64}$ ]] \
        || [[ "$(wc -c <"$token_file")" -ne 64 ]]; then
        echo "Syncthing relay token must contain exactly 64 lowercase hexadecimal characters." >&2
        exit 1
      fi
      unset token

      # Syncthing may be restarting after syncthing-init, so retry for a while.
      api() {
        curl -sSLf -H "@$headers" --retry 60 --retry-delay 1 --retry-all-errors "$@"
      }

      # Replaces an address list with the declared addresses plus the relay.
      patch() {
        local path="$1" key="$2" addresses="$3"
        jq -n \
          --rawfile token "$token_file" \
          --arg relay ${lib.escapeShellArg relayAddress} \
          --arg key "$key" \
          --argjson addresses "$addresses" \
          '{($key): ($addresses + ["\($relay)&token=\($token | @uri)"])}' |
          api --json @- -X PATCH "http://${cfg.guiAddress}/rest/config/$path"
      }

      patch options listenAddresses ${lib.escapeShellArg (builtins.toJSON cfg.settings.options.listenAddresses)}
      patch devices/${cfg.settings.devices.truenas.id} addresses ${lib.escapeShellArg (builtins.toJSON cfg.settings.devices.truenas.addresses)}

      if api "http://${cfg.guiAddress}/rest/config/restart-required" | jq -e .requiresRestart >/dev/null; then
        api -X POST "http://${cfg.guiAddress}/rest/system/restart"
      fi
    '';
  };

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
  sops.secrets."syncthing-relay/token" = { };

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

    # The relay address is appended by addRelayAddress.
    settings = {
      devices.truenas = {
        id = "M5SSSMH-PPOUKC6-BJDJGK3-GBVAPKD-MTCSSJL-YPIDJSA-353WMNO-CP27FA5";
        addresses = [ "tcp://truenas.lan:22000" ];
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
        ];
        localAnnounceEnabled = false;
        natEnabled = false;
        relaysEnabled = true;
      };
    };
  };

  # syncthing-init overwrites the address lists with the declared ones on every
  # run, so the relay address has to be appended right after it. The token is
  # decrypted by sops-nix.service.
  systemd.user.services.syncthing-init = {
    Unit.After = [ "sops-nix.service" ];
    Service.ExecStartPost = lib.getExe addRelayAddress;
  };
}
