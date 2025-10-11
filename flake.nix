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
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      deploy-rs,
      ...
    }@inputs:
    let
      mkSystem =
        { name }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./systems/${name}
          ];
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
        dns1 = mkSystem { name = "dns1"; };
        dns2 = mkSystem { name = "dns2"; };
        builder = mkSystem { name = "builder"; };
      };

      deploy.nodes = {
        dns1 = mkDeploy {
          name = "dns1";
          addr = "10.1.53.10";
        };
        dns2 = mkDeploy {
          name = "dns2";
          addr = "10.1.53.11";
        };
        builder = mkDeploy {
          name = "builder";
          addr = "10.1.1.155";
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
