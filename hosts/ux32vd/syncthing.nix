# Syncthing runs as a user service after login. Its native Plasma widget uses
# the daemon's default config and API location without a separate tray service.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # TODO
  remote = {
    enable = false;
    id = "REPLACE_WITH_REMOTE_DEVICE_ID";
    addresses = [
      "tcp://REPLACE_WITH_REMOTE_HOST:22000"
      "dynamic"
    ];
  };

  # TODO
  receiveFromRemote = {
    enable = false;
    id = "REPLACE_WITH_RECEIVE_FOLDER_ID";
    relativePath = "Sync/REPLACE_WITH_RECEIVE_PATH";
  };

  # TODO
  sendToRemote = {
    enable = false;
    id = "REPLACE_WITH_SEND_FOLDER_ID";
    relativePath = "Sync/REPLACE_WITH_SEND_PATH";
  };

  enabled = folder: remote.enable && folder.enable;
in
{
  home.packages = [
    # Provides martchus.syncthingplasmoid, enabled in plasma.nix. The minimal
    # Syncthing Tray package does not include the Plasma integration.
    pkgs.syncthingtray
  ];

  home.file =
    lib.optionalAttrs (enabled receiveFromRemote) {
      "${receiveFromRemote.relativePath}/.stignore".source = ../../dotfiles/.stignore;
    }
    // lib.optionalAttrs (enabled sendToRemote) {
      "${sendToRemote.relativePath}/.stignore".source = ../../dotfiles/.stignore;
    };

  services.syncthing = {
    enable = true;

    settings = {
      options.relaysEnabled = false;

      devices = lib.optionalAttrs remote.enable {
        remote = {
          inherit (remote) id addresses;
        };
      };

      folders =
        lib.optionalAttrs (enabled receiveFromRemote) {
          receive-from-remote = {
            inherit (receiveFromRemote) id;
            label = "Receive from remote";
            path = "${config.home.homeDirectory}/${receiveFromRemote.relativePath}";
            type = "receiveonly";
            devices = [ "remote" ];
          };
        }
        // lib.optionalAttrs (enabled sendToRemote) {
          send-to-remote = {
            inherit (sendToRemote) id;
            label = "Send to remote";
            path = "${config.home.homeDirectory}/${sendToRemote.relativePath}";
            type = "sendonly";
            devices = [ "remote" ];
          };
        };
    };
  };
}
