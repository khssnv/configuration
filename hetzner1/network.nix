{ hostname, ...}:

{
  networking = {
    hostName = "${hostname}";
    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [ 
        22 # ssh
        # 80 # http
        # 443 # https
        # 4001
        # 9090 # Prometheus UI
        9093 # Prometheus alertmanager
        9944 # robonomics node dapp API
        # 31163
        # 30333
        30363 # robonomics network
      ];
      allowedUDPPorts = [
        # 30333
        # 53741
        # 42000
      ];
    };
  };
}
