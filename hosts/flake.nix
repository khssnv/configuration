{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";

    # Stable still packages Bitwarden with EOL Electron 39.
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Skill sources for the coding agents, see agents.nix. Plain
    # sources, not flakes, so they are fetched only to be pinned in flake.lock.
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

      mkHost =
        {
          hostName,
          systemModule,
          homeModule,
        }:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit hostName userName; };

          modules = [
            systemModule
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit hostName inputs userName;
                  pkgsUnstable = nixpkgs-unstable.legacyPackages.x86_64-linux;
                };
                users.${userName} = import homeModule;
                backupFileExtension = "home-manager.backup";
                overwriteBackup = true;
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        d25 = mkHost {
          hostName = "d25";
          systemModule = ./d25/configuration.nix;
          homeModule = ./d25/home.nix;
        };

        ux32vd = mkHost {
          hostName = "ux32vd";
          systemModule = ./ux32vd/configuration.nix;
          homeModule = ./ux32vd/home.nix;
        };
      };
    };
}
