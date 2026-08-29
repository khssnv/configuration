# Syncthing runs as a user service after login.
{
  lib,
  pkgs,
  ...
}:

let
  keepassxcPath = "Documents/Secrets/KeePassXC";
  relayId = "NG7SSGM-437H2EG-PKE5C4C-RELJWMC-6JPIQPC-3KREKST-7APKFTC-NRETUAB";
  relayToken = "change-me";
  relayUrl = "relay://2.vpsza500.khassanov.xyz:22067/?id=${relayId}&token=${relayToken}";
in
{
  # Syncthing refuses a symlinked .stignore, so copy a regular file instead of
  # managing it with home.file.
  home.activation.installSyncthingIgnore = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${lib.getExe' pkgs.coreutils "install"} -Dm644 ${../dotfiles/.stignore} "$HOME/${keepassxcPath}/.stignore"
  '';

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
