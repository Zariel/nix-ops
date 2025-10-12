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
    services.bind = {
      listenOn = [ "127.0.0.1" ];
      listenOnIpv6 = [ "::1" ];
      listenOnPort = 20053;

      cacheNetworks = [
        "10.1.0.0/24" # LAN
        "10.1.1.0/24" # SERVERS
        "10.1.2.0/24" # TRUSTED
        "10.1.3.0/24" # IOT
        "192.168.2.0/24" # GUEST
        "10.5.0.0/24" # CONTAINERS
        "10.254.1.0/24" # L3 servers
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
  };
}
