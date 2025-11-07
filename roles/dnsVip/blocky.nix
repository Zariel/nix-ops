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
    services.blocky = {
      settings = {
        ports = {
          dns = "127.0.53.20:53";
          http = 4000;
        };

        upstreams = {
          groups.default = [
            "tcp-tls:1.1.1.1:853" # Cloudflare primary
            "tcp-tls:1.0.0.1:853" # Cloudflare secondary
            "tcp-tls:8.8.8.8:853" # Google DNS primary
            "tcp-tls:9.9.9.9:853" # Quad9 (privacy-focused, DNSSEC)
          ];

          # Explicitly enable parallel query hedging for reliability
          # Picks 2 random upstreams per query, returns fastest response
          strategy = "parallel_best";

          # Timeout per upstream query attempt (1s is reasonable for hedged DoT queries)
          timeout = "1s";
        };

        ecs.useAsClient = true;

        prometheus = {
          enable = true;
          path = "/metrics";
        };

        blocking = {
          loading = {
            concurrency = 10;
            strategy = "fast";
            downloads.timeout = "4m";
          };

          denylists = {
            ads = [
              "https://raw.githubusercontent.com/Zariel/adlists/main/blocklist.txt"
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
              "https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt"
              "https://malware-filter.gitlab.io/malware-filter/urlhaus-filter-domains.txt"
              "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts;showintro=0"
              "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/tif.txt"
              "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/popupads.txt"
              "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/pro.txt"
            ];
            fakenews = [
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-only/hosts"
            ];
            gambling = [
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-only/hosts"
            ];
          };

          allowlists.ads = [
            "https://raw.githubusercontent.com/Zariel/adlists/main/allowlist.txt"
            "https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/whitelist.txt"
            "www.thrivingautistic.org"
          ];

          clientGroupsBlock.default = [
            "ads"
            "fakenews"
            "gambling"
          ];
        };
      };
    };

    # Ensure blocky starts after the blocky interface is ready
    systemd.services.blocky = {
      after = [ "sys-subsystem-net-devices-blocky.device" ];
      bindsTo = [ "sys-subsystem-net-devices-blocky.device" ];
    };
  };
}
