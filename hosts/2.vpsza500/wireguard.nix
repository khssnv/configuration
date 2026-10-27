{
  networking.firewall.allowedUDPPorts = [ 51820 ];

  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.201.0.1/30" ];
    listenPort = 51820;
    privateKeyFile = "/var/lib/wireguard/private.key";
    generatePrivateKeyFile = true;

    peers = [
      {
        publicKey = "m2aZkF2H8rV2herTLJXh175797eHk5LW9TcE3UlN1Vg=";
        allowedIPs = [ "10.201.0.2/32" ];
      }
    ];
  };
}
