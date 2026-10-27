{
  pkgs,
  ...
}:

{
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 80 443 ];

  security.acme = {
    acceptTerms = true;
    defaults.email = "a.khssnv@gmail.com";
  };

  services.nginx = {
    enable = true;

    virtualHosts."ingress.khassanov.xyz" = {
      root = "${pkgs.nginx}/html";
      enableACME = true;
      forceSSL = true;
    };
  };
}
