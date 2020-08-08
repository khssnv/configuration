{ pkgs, ... }:

{
  programs = {
    # mosh.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "qt";
    };
  };
}
