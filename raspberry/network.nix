{ config, ... }:

{
  networking.hostName = "raspberry";
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  networking.interfaces.wlan0.useDHCP = true;
  networking.wireless = {
    enable = true;
    networks = {
      "REMY Robotics" = {
        psk = "askPeterHeKnowsIt";
      };
      "MOVISTAR_A4F8" = {
        psk = "NHSQhsgjnsFoBpWRwHhT";
      };
    };
  };

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    22 # ssh
  ];
  networking.firewall.allowedUDPPorts = [ ];
}
