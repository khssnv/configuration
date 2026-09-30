{ config, ... }:

{
  sops.secrets."syncthing-relay/token" = { };

  # strelaysrv takes the token only as a command line flag. systemd substitutes
  # it from the environment file, so the token stays out of the Nix store.
  # TODO: read the token from a file once strelaysrv supports it:
  # https://github.com/syncthing/syncthing/issues/10888
  sops.templates."syncthing-relay.env" = {
    content = "TOKEN=${config.sops.placeholder."syncthing-relay/token"}";
    restartUnits = [ "syncthing-relay.service" ];
  };

  systemd.services.syncthing-relay = {
    preStart = ''
      if [[ ! "''${TOKEN:-}" =~ ^[0-9a-f]{64}$ ]]; then
        echo "Syncthing relay token must contain exactly 64 lowercase hexadecimal characters." >&2
        exit 1
      fi
    '';
    serviceConfig.EnvironmentFile = config.sops.templates."syncthing-relay.env".path;
  };

  services.syncthing.relay = {
    enable = true;
    pools = [ ];
    statusListenAddress = "127.0.0.1";
    extraOptions = [ "--token=\${TOKEN}" ];
  };

  networking.firewall.allowedTCPPorts = [ 22067 ];
}
