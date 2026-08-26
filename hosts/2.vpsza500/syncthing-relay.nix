let
  token = "change-me";
in
{
  assertions = [
    {
      assertion =
        token != ""
        && token != "change-me"
        && builtins.stringLength token >= 64;
      message = "Syncthing relay token must be non-empty, not \"change-me\", at least 64 chars, printable non-space ASCII.";
    }
  ];

  services.syncthing.relay = {
    enable = true;
    pools = [ ];
    statusListenAddress = "127.0.0.1";
    extraOptions = [ "--token=${token}" ];
  };

  networking.firewall.allowedTCPPorts = [ 22067 ];
}
