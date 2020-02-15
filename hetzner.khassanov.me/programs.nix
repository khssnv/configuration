{ pkgs, ... }:

{
  programs = {
    # mosh.enable = true;
  };
  environment.systemPackages = with pkgs; [
    htop
  ];
}
