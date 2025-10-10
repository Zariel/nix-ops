{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.dnsdist = {
    enable = true;
    listenAddress = "172.53.53.53";
    listenPort = 53;
    extraConfig = (builtins.readFile ./files/dnsdist/config.lua);
  };

  services.blocky = {
    enable = true;
  };

  services.bind = {
    enable = true;
  };

  services.bird = {
    enable = true;
    config = ''
      router id 10.1.53.10;

      protocol device {
        scan time 10;
      }

      protocol direct {
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
}
