# Syncthing runs as a user service after login.
{
  lib,
  pkgs,
  ...
}:

{
  # Syncthing refuses a symlinked .stignore, so copy a regular file instead of
  # managing it with home.file.
  home.activation.installSyncthingIgnore = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${lib.getExe' pkgs.coreutils "install"} -Dm644 ${../dotfiles/.stignore} "$HOME/Workspace/github.com/.stignore"
  '';

  services.syncthing = {
    enable = true;

    settings = {
      devices.truenas = {
        id = "M5SSSMH-PPOUKC6-BJDJGK3-GBVAPKD-MTCSSJL-YPIDJSA-353WMNO-CP27FA5";
        addresses = [ "tcp://truenas.lan:22000" ];
      };

      folders = {
        "KeePassXC" = rec {
          label = path;
          path = "~/Documents/Secrets/KeePassXC";
          devices = [ "truenas" ];
        };
      };

      options = {
        globalAnnounceEnabled = false;
        localAnnounceEnabled = false;
        natEnabled = false;
        relaysEnabled = false;
      };
    };
  };
}
