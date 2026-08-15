{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.dnsVip;
in
{
  config = mkIf cfg.enable {
    services.bird = {
      config = ''
        router id ${cfg.nodeIp};

        protocol device {
          scan time 10;
        }

        protocol direct dnsvip_direct {
          disabled;
          interface "dnsvip";
          ipv4;
        }

        protocol kernel {
          ipv4 {
            import none;
            export all;
          };
        }

        protocol bgp dnsvip_bgp {
          local as ${toString cfg.bgpLocalAs};
          neighbor ${cfg.bgpPeerIp} as ${toString cfg.bgpPeerAs};

          ipv4 {
            import none;
            export where source = RTS_DEVICE;
          };
        }
      '';
    };
  };
}
