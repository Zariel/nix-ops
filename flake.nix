{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      deploy-rs,
      disko,
      ...
    }@inputs:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-darwin"
      ];

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

            # Extended timeouts for OSPF adjacency formation during deployments
            activationTimeout = 300; # 5 minutes (allows for OSPF convergence)
            confirmTimeout = 45; # 45 seconds (slightly longer than default 30s)

            # Enable automatic rollback on failure
            magicRollback = true;
            autoRollback = true;
          };
        };

      mkHome =
        {
          config,
          ...
        }:
        let
          hostHome = builtins.path {
            path = "${toString ./systems}/${config.networking.hostName}/home.nix";
          };
        in
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.chris = {
              imports = [
                ./homes/chris
                hostHome
              ];
            };
            extraSpecialArgs = {
              inherit
                inputs
                self
                ;
            };
          };
        };
    in
    {
      devShells = forAllSystems (system: {
        default =
          let
            pkgs = import nixpkgs { inherit system; };
          in
          pkgs.mkShell {
            packages = [
              deploy-rs.packages.${system}.deploy-rs
            ];
          };
      });

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
        matchbox = mkSystem {
          name = "matchbox";
          extraModules = [
            ./roles/server
            disko.nixosModules.disko
          ];
        };
        gaming = mkSystem {
          name = "gaming";
          extraModules = [
            home-manager.nixosModules.home-manager
            mkHome
          ];
        };
        dev = mkSystem {
          name = "dev";
          extraModules = [
            disko.nixosModules.disko
            ./roles/server
            home-manager.nixosModules.home-manager
            mkHome
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
          addr = "10.254.53.0";
        };
        dns2 = mkDeploy {
          name = "dns2";
          addr = "10.254.53.2";
        };
        dns3 = mkDeploy {
          name = "dns3";
          addr = "10.254.53.4";
        };
        dev = mkDeploy {
          name = "dev";
          addr = "10.1.2.15";
        };
        matchbox = mkDeploy {
          name = "matchbox";
          addr = "10.1.1.20";
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
