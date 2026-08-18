{ pkgs, userName, ... }:

let
  benqDisplayPilot2 = pkgs.callPackage ./pkgs/benq-display-pilot-2.nix { };
in

{
  hardware.i2c.enable = true;

  users.users.${userName}.extraGroups = [ "i2c" ];

  home-manager.users.${userName} = {
    home.packages = [ benqDisplayPilot2 ];

    xdg.configFile."autostart/com.benq.DisplayPilot2.desktop".source =
      "${benqDisplayPilot2}/share/applications/com.benq.DisplayPilot2.desktop";
  };
}
