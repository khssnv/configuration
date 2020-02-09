{
  networking = {
    hostName = "hetzner.khassanov.me";
    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [ 22 80 443 4001 31163 30333 ];
      allowedUDPPorts = [ 30333 53741 42000 ];
    };
  };
}
