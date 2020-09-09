{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    virtualboxWithExtpack
  ];

  programs = {
    # mosh.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "qt";
    };
  };

  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };

  users.extraGroups.vboxusers.members = [ "khassanov" ];
  nixpkgs.config.allowUnfree = true;
}
