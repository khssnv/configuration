{ hostname, ... }:

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
        # 31163
        # 30333
      ];
      allowedUDPPorts = [
        # 30333
        # 53741
        # 42000
      ];
    };
    networkmanager.enable = true;
    interfaces.wlp3s0.useDHCP = true;
    # wireless = {
    #   enable = true;
    #   interfaces = [ "wlp3s0" ];
    #   userControlled.enable = true;
    # };
  };
}
