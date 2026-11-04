{
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.hosts."10.201.0.2" = [ "ingress" ];

  services.nginx = {
    enable = true;

    streamConfig = ''
      server {
        listen 80;
        proxy_pass ingress:80;
      }

      server {
        listen 443;
        proxy_pass ingress:443;
      }
    '';
  };
}