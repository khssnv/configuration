{
  networking.firewall.allowedUDPPorts = [ 51820 ];

  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.201.0.1/30" ];
    listenPort = 51820;
    privateKeyFile = "/var/lib/wireguard/private.key";
    generatePrivateKeyFile = true;

    peers = [
      {
        publicKey = "BrWonxVQksZcLq0MCJgees+pD9G5sWVblu11K9z1lms=";
        allowedIPs = [ "10.201.0.2/32" ];
      }
    ];
  };
}
