{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      deploy-rs,
      chaotic,
      ...
    }@inputs:
    let
      mkSystem =
        {
          name,
          extraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./roles/base
            ./systems/${name}
          ]
          ++ extraModules;
        };

      mkDeploy =
        { name, addr }:
        {
          hostname = addr;
          profiles.system = {
            sshUser = "chris";
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.${name};
          };
        };
    in
    {
      nixosConfigurations = {
        dns1 = mkSystem {
          name = "dns1";
          extraModules = [ ./roles/server ];
        };
        dns2 = mkSystem {
          name = "dns2";
          extraModules = [ ./roles/server ];
        };
        dns3 = mkSystem {
          name = "dns3";
          extraModules = [ ./roles/server ];
        };
        builder = mkSystem {
          name = "builder";
          extraModules = [ ./roles/server ];
        };
        gaming = mkSystem {
          name = "gaming";
          extraModules = [
            chaotic.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.chris = {
                  imports = [
                    ./homes/chris
                    ./systems/gaming/home.nix
                  ];
                };
                extraSpecialArgs = {
                  inherit
                    inputs
                    self
                    ;
                };
              };
            }
          ];
        };
      };

      deploy.nodes = {
        builder = mkDeploy {
          name = "builder";
          addr = "10.1.1.155";
        };
        dns1 = mkDeploy {
          name = "dns1";
          addr = "10.1.53.10";
        };
        dns2 = mkDeploy {
          name = "dns2";
          addr = "10.1.53.11";
        };
        dns3 = mkDeploy {
          name = "dns3";
          addr = "10.1.53.12";
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
