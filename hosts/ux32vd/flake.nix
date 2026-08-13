{
  # inputs.nixpkgs.url = "github.com:NixOS/nixpkgs/nixos-26.05";
  inputs.nixpkgs.url = "nixpkgs/nixos-26.05";

  # Stable still packages Bitwarden with EOL Electron 39.
  inputs.nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

  inputs.home-manager = {
    url = "github:nix-community/home-manager/release-26.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.plasma-manager = {
    url = "github:nix-community/plasma-manager";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };

  # Skill sources for the coding agents, see agents.nix. Plain sources, not
  # flakes, so they are fetched only to be pinned in flake.lock.
  inputs.caveman = {
    url = "github:JuliusBrussee/caveman";
    flake = false;
  };

  outputs =
    {
      home-manager,
      nixpkgs,
      nixpkgs-unstable,
      plasma-manager,
      ...
    }@inputs:
    let
      userName = "alisher";
    in
    {
      nixosConfigurations.ux32vd = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit userName; };

        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs userName;
                pkgsUnstable = nixpkgs-unstable.legacyPackages.x86_64-linux;
              };
              sharedModules = [ plasma-manager.homeModules.plasma-manager ];
              users.${userName} = import ./home.nix;
              backupFileExtension = "home-manager.backup";
              overwriteBackup = true;
            };
          }
        ];
      };
    };
}
