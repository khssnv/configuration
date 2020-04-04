{ pkgs, ... }:

{
  users.extraUsers.khassanov = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/khassanov";
    description = "Alisher A. Khassanov";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    # openssh.authorizedKeys.keys = import ./keys.nix;
  };

}
