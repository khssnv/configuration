# Document Scanner runs this script after saving a scan.
{ lib, pkgs, ... }:

let
  postprocessing = pkgs.writeShellApplication {
    name = "simple-scan-postprocessing";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.libnotify
      pkgs.ocrmypdf
    ];
    text = builtins.readFile ../scripts/simple-scan-postprocessing.sh;
  };
in
{
  dconf.settings."org/gnome/simple-scan" = {
    postproc-enabled = true;
    postproc-script = lib.getExe postprocessing;
  };
}
