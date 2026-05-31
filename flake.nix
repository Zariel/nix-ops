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

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # codex-cli-nix = {
    #   url = "github:sadjow/codex-cli-nix";
    #   # inputs.nixpkgs.follows = "nixpkgs";
    # };

    # beads = {
    #   url = "github:steveyegge/beads";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      deploy-rs,
      disko,
      treefmt-nix,
      catppuccin,
      nixos-hardware,
      sops-nix,
      ...
    }@inputs:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      treefmtEval = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        treefmt-nix.lib.evalModule pkgs ./treefmt.nix
      );

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
            sops-nix.nixosModules.sops
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
          hostPath = "${toString ./systems}/${config.networking.hostName}";
          hostHome =
            if builtins.pathExists "${hostPath}/home/default.nix" then
              builtins.path {
                path = "${hostPath}/home";
              }
            else
              builtins.path {
                path = "${hostPath}/home.nix";
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
                catppuccin.homeModules.catppuccin
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
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

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

      packages = forAllSystems (system: {
        git-commit-wrapped = nixpkgs.legacyPackages.${system}.callPackage ./packages/git-commit-wrapped { };
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
            catppuccin.nixosModules.catppuccin
            home-manager.nixosModules.home-manager
            mkHome
          ];
        };
        thinliz = mkSystem {
          name = "thinliz";
          extraModules = [
            disko.nixosModules.disko
            catppuccin.nixosModules.catppuccin
            home-manager.nixosModules.home-manager
            nixos-hardware.nixosModules.common-cpu-intel
            nixos-hardware.nixosModules.common-gpu-intel
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
        thinliz = mkDeploy {
          name = "thinliz";
          addr = "10.1.2.102";
        };
      };

      checks =
        nixpkgs.lib.recursiveUpdate
          (builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib)
          (
            forAllSystems (system: {
              formatting = treefmtEval.${system}.config.build.check self;
            })
          );
    };
}
