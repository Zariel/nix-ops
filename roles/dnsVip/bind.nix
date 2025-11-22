{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.dnsVip;
  bindZoneChecks = attrsets.mapAttrsToList (
    zoneName: zoneCfg: "${pkgs.bind}/bin/named-checkzone ${zoneName} ${zoneCfg.file}"
  ) config.services.bind.zones;

  bindPreflight = pkgs.writeShellScript "bind-preflight" ''
    set -euo pipefail
    ${pkgs.bind}/bin/named-checkconf ${config.services.bind.configFile}
    ${concatStringsSep "\n    " bindZoneChecks}
  '';
in
{
  config = mkIf cfg.enable {
    services.bind = {
      listenOn = [ "127.0.53.10" ];
      ipv4Only = true;

      cacheNetworks = [
        "10.1.0.0/24" # LAN
        "10.1.1.0/24" # SERVERS
        "10.1.2.0/24" # TRUSTED
        "10.1.3.0/24" # IOT
        "192.168.2.0/24" # GUEST
        "10.5.0.0/24" # VYOS CONTAINERS
        "10.254.0.0/16" # L3 servers
      ];

      extraConfig = ''
        logging {
          channel stdout {
            stderr;
            severity info;
            print-category yes;
            print-severity yes;
            print-time yes;
          };
          category security { stdout; };
          category dnssec   { stdout; };
          category default  { stdout; };
        };
      '';

      zones = {
        "cbannister.casa" = {
          master = true;
          file = ./files/bind/zones/db.cbannister.casa;
        };

        "unifi" = {
          master = true;
          file = ./files/bind/zones/db.unifi;
        };

        "0.1.10.in-addr.arpa" = {
          master = true;
          file = ./files/bind/zones/db.0.1.10.in-addr.arpa;
        };

        "1.1.10.in-addr.arpa" = {
          master = true;
          file = ./files/bind/zones/db.1.1.10.in-addr.arpa;
        };

        "2.1.10.in-addr.arpa" = {
          master = true;
          file = ./files/bind/zones/db.2.1.10.in-addr.arpa;
        };

        "3.1.10.in-addr.arpa" = {
          master = true;
          file = ./files/bind/zones/db.3.1.10.in-addr.arpa;
        };

        "8.1.10.in-addr.arpa" = {
          master = true;
          file = ./files/bind/zones/db.8.1.10.in-addr.arpa;
        };

        "2.168.192.in-addr.arpa" = {
          master = true;
          file = ./files/bind/zones/db.2.168.192.in-addr.arpa;
        };
      };
    };

    # Ensure bind starts after the bind interface is ready
    systemd.services.bind = {
      after = [ "sys-subsystem-net-devices-bind.device" ];
      bindsTo = [ "sys-subsystem-net-devices-bind.device" ];
      serviceConfig = {
        ExecStartPre = bindPreflight;
        Restart = "on-failure";
        RestartSec = "5s";
        StartLimitIntervalSec = 60;
        StartLimitBurst = 5;
        TimeoutStartSec = "30s";
      };
    };
  };
}
