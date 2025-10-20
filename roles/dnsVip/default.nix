{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.dnsVip;
in
{
  imports = [
    ./bind.nix
    ./blocky.nix
    ./dnsdist.nix
    ./bird.nix
    ./dns-ha.nix
  ];

  options.services.dnsVip = {
    enable = mkEnableOption "DNS VIP anycast service";

    nodeIp = mkOption {
      type = types.str;
      description = "Node IP address (used for BIRD router-id and health check identification)";
      example = "10.1.53.10";
    };
  };

  config = mkIf cfg.enable {
    # Configure VIP dummy interfaces
    systemd.network = {
      enable = true;

      netdevs."10-dnsvip" = {
        netdevConfig = {
          Kind = "dummy";
          Name = "dnsvip";
        };
      };

      networks."20-dnsvip" = {
        matchConfig.Name = "dnsvip";
        networkConfig.ConfigureWithoutCarrier = true;
        address = [
          "172.53.53.53/32"
          "fd74:f571:d3bd:53::53/128"
        ];
      };

      # Bind dummy interface
      netdevs."11-bind" = {
        netdevConfig = {
          Kind = "dummy";
          Name = "bind";
        };
      };

      networks."21-bind" = {
        matchConfig.Name = "bind";
        networkConfig.ConfigureWithoutCarrier = true;
        address = [ "127.0.53.10/32" ];
      };

      # Blocky dummy interface
      netdevs."12-blocky" = {
        netdevConfig = {
          Kind = "dummy";
          Name = "blocky";
        };
      };

      networks."22-blocky" = {
        matchConfig.Name = "blocky";
        networkConfig.ConfigureWithoutCarrier = true;
        address = [ "127.0.53.20/32" ];
      };
    };

    # Enable all DNS services
    services.dnsdist.enable = true;
    services.bind.enable = true;
    services.blocky.enable = true;
    services.bird.enable = true;

    # Pass nodeIp to health check service
    services.dnsHealthcheck = {
      enable = true;
      nodeIp = cfg.nodeIp;
    };

    # DNS-specific packages
    environment.systemPackages = with pkgs; [
      doggo
    ];
  };
}
