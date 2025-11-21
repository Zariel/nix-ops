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

        protocol ospf v2 ospf4 {
          ipv4 {
            import none;
            export where source = RTS_DEVICE;
          };

          area 0.0.0.0 {
            interface "ens*" {
              type pointopoint;
              cost 10;
            };
          };
        };

        protocol direct dnsvip_direct_v6 {
          disabled;
          interface "dnsvip";
          ipv6;
        }

        protocol kernel {
          ipv6 {
            import none;
            export all;
          };
        }

        protocol ospf v3 ospf6 {
          router id ${cfg.nodeIp};

          ipv6 {
            import none;
            export where source = RTS_DEVICE;
          };

          area 0.0.0.0 {
            interface "ens*" {
              type pointopoint;
              cost 10;
            };
          };
        };
      '';
    };
  };
}
