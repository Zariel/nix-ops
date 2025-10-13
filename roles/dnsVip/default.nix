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
    # Configure VIP dummy interface
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
