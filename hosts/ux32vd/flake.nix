{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";

    # Stable still packages Bitwarden with EOL Electron 39.
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Skill sources for the coding agents, see agents.nix. Plain sources, not
    # flakes, so they are fetched only to be pinned in flake.lock.
    caveman = {
      url = "github:JuliusBrussee/caveman";
      flake = false;
    };
  };

  outputs =
    {
      home-manager,
      nixpkgs,
      nixpkgs-unstable,
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
              users.${userName} = import ./home.nix;
              backupFileExtension = "home-manager.backup";
              overwriteBackup = true;
            };
          }
        ];
      };
    };
}
