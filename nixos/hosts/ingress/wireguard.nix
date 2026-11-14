{
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.201.0.2/30" ];
    privateKeyFile = "/var/lib/wireguard/private.key";
    generatePrivateKeyFile = true;

    peers = [
      {
        publicKey = "RLKYnRJVXvUjpUOvz4ku7gLba6ziqyyJjhnZxSPqnUk=";
        endpoint = "2.vpsza500.khassanov.xyz:51820";
        allowedIPs = [ "10.201.0.1/32" ];
        persistentKeepalive = 25;
      }
    ];
  };
}
