{ pkgs, ... }:

{
  services = {
    openssh = {
      enable = true;
      passwordAuthentication = false;
      permitRootLogin = "yes";
    };

    # cjdns = {
    #   enable = true;
    #   ETHInterface = {
    #     bind = "all";
    #     beacon = 2;
    #   };
    #   UDPInterface = {
    #     bind = "0.0.0.0:42000";
    #     connectTo = {
    #       # Akru/Strasbourg
    #       "164.132.111.49:53741" = {
    #         password = "cr36pn2tp8u91s672pw2uu61u54ryu8";
    #         publicKey = "35mdjzlxmsnuhc30ny4rhjyu5r1wdvhb09dctd1q5dcbq6r40qs0.k";
    #       };
    #       # Airalab/DigitalOcean
    #       "188.226.158.11:25829" = {
    #         password = ";@d.LP2589zUUA24837|PYFzq1X89O";
    #         publicKey = "kpu6yf1xsgbfh2lgd7fjv2dlvxx4vk56mmuz30gsmur83b24k9g0.k";
    #       };
    #     };
    #   };
    #   # confFile = "/etc/cjdroute.conf";
    # };

    # ipfs = {
    #   enable = true;
    #   localDiscovery = false;
    # };
    
    ntp = {
      enable = true;
      servers = [ "0.pool.ntp.org" "1.pool.ntp.org" ];
    };

    # nginx = {
    #   enable = true;
    #   recommendedTlsSettings   = true;
    #   recommendedGzipSettings  = true;
    #   recommendedOptimisation  = true;
    #   virtualHosts = {
    #     "khassanov.me" = {
    #       forceSSL = true;
    #       enableACME = true;
    #       locations = { };
    #     };
    #     "hetzner.khassanov.me" = {
    #       forceSSL = true;
    #       enableACME = true;
    #       locations = { };
    #     };
    #     "sandbox.khassanov.me" = {
    #       forceSSL = true;
    #       enableACME = true;
    #       locations = {
    #         "/hello.txt".root = "/var/www";
    #       };
    #     };
    #   };
    # };
    prometheus = {
      enable = true;
      configText = builtins.readFile ./prometheus.yml;
      # configText = "
      #   global:
      #     scrape_interval: 30s
      #     external_labels:
      #       monitor: 'khassanov.me'
      #   scrape_configs:
      #     - job_name: 'nodes'
      #       static_configs:
      #         - targets: ['localhost:9100']
      # ";
      exporters.node = {
        enable = true;
        enabledCollectors = [ "loadavg" "meminfo" ];
      };
    };
  };
}
