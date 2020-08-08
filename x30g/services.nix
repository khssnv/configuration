{ config, pkgs, ... }:

{
  services = {
    openssh = {
      enable = true;
      passwordAuthentication = false;
      permitRootLogin = "yes";
    };

    ntp = {
      enable = true;
      servers = [ "0.pool.ntp.org" "1.pool.ntp.org" ];
    };

    # prometheus = {
    #   enable = true;
    #   configText = builtins.readFile "/etc/nixos/${config.networking.hostName}/prometheus.yml";
    #   # configText = builtins.readFile /home/khassanov/Workspace/configuration/hetzner.khassanov.me/monitoring/server/prometheus.yml;
    #   # configText = "
    #   #   global:
    #   #     scrape_interval: 30s
    #   #     external_labels:
    #   #       monitor: 'khassanov.me'
    #   #   scrape_configs:
    #   #     - job_name: 'nodes'
    #   #       static_configs:
    #   #         - targets: ['localhost:9100']
    #   # ";
    #   exporters.node = {
    #     enable = true;
    #     enabledCollectors = [ "loadavg" "meminfo" ];
    #   };
    # };
  };
}
