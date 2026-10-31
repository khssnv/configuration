{
  inputs.nixpkgs.url = "nixpkgs/nixos-26.05";

  outputs =
    { nixpkgs, ... }:
    {
      nixosConfigurations.hypervisor = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./configuration.nix ];
      };
    };
}
