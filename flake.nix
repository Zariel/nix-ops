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

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
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

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    proton-cachy = {
      url = "github:Zariel/proton-cachy.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      deploy-rs,
      llm-agents,
      codex-cli-nix,
      treefmt-nix,
      catppuccin,
      sops-nix,
      proton-cachy,
      ...
    }:
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
          specialArgs ? { },
        }:
        nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
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

            # Extended timeouts for routing convergence during deployments
            activationTimeout = 300; # 5 minutes (allows for BGP convergence)
            confirmTimeout = 45; # 45 seconds (slightly longer than default 30s)

            # Enable automatic rollback on failure
            magicRollback = true;
            autoRollback = true;
          };
        };

      mkHome = hostHome: {
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
            inherit codex-cli-nix llm-agents;
          };
        };
      };
    in
    {
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        nixpkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          gamemode-waybar = pkgs.callPackage ./packages/gamemode-waybar/package.nix { };
        }
      );

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
        gaming = mkSystem {
          name = "gaming";
          specialArgs = { inherit proton-cachy; };
          extraModules = [
            catppuccin.nixosModules.catppuccin
            home-manager.nixosModules.home-manager
            (mkHome ./systems/gaming/home)
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
      };

      checks = forAllSystems (
        system:
        {
          formatting = treefmtEval.${system}.config.build.check self;
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") (
          deploy-rs.lib.x86_64-linux.deployChecks self.deploy
        )
      );
    };
}
