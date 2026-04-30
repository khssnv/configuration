{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    buildah
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

  virtualisation.podman.enable = true;
  virtualisation.docker.enable = true;

  users.extraGroups.vboxusers.members = [ "khassanov" ];
  nixpkgs.config.allowUnfree = true;
}
