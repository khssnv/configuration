{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { nixpkgs, ... }:
    {
      nixosConfigurations.rockpix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./configuration.nix ];
      };
    };
}
