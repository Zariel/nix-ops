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
          interface "dnsvip";
          ipv4;
        }

        protocol kernel {
          ipv4 {
            import none;
            export all;
          };
        }

        protocol ospf v2 {
          ipv4 {
            import none;
            export where source = RTS_DEVICE;
          };

          area 0.0.0.0 {
            interface "ens*" {
              type broadcast;
              cost 10;
            };
          };
        };
      '';
    };
  };
}
