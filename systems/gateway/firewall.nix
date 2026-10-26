{ lib, ... }:
let
  zones = {
    wan = [ "wan0" ];
    lan = [ "bond0.100" ];
    servers = [ "bond0.10" ];
    trusted = [
      "bond0.20"
      "wg01"
    ];
    guest = [ "bond0.30" ];
    iot = [ "bond0.40" ];
    containers = [ "pod-containers" ];
    transit = [ "bond0.3001" ];
  };
  interfaces = names: "{ " + lib.concatMapStringsSep ", " (n: ''"${n}"'') names + " }";
  dispatch =
    hook:
    lib.concatStringsSep "\n" (
      lib.concatMap
        (
          family:
          lib.concatMap (
            src:
            lib.concatMap (
              dst:
              lib.optional
                (src != dst && (hook == "forward" || (if hook == "input" then dst == "local" else src == "local")))
                (
                  "meta nfproto ${family} "
                  + lib.optionalString (src != "local") "iifname ${interfaces zones.${src}} "
                  + lib.optionalString (dst != "local") "oifname ${interfaces zones.${dst}} "
                  + "jump ${if family == "ipv4" then "ip" else "ip6"}_${src}_${dst}"
                )
            ) (if hook == "input" then [ "local" ] else builtins.attrNames zones)
          ) (if hook == "output" then [ "local" ] else builtins.attrNames zones)
        )
        [
          "ipv4"
          "ipv6"
        ]
    );
in
{
  boot.kernelModules = [ "nf_conntrack_tftp" ];
  networking.firewall.enable = false;
  networking.nftables = {
    enable = true;
    flushRuleset = false;
    tables.gateway = {
      family = "inet";
      content =
        builtins.readFile ./geoip-cn-ru.nft
        + builtins.readFile ./zone-policy.nft
        + ''
          ct helper tftp {
            type "tftp" protocol udp;
            l3proto ip;
          }
          chain helpers {
            type filter hook prerouting priority mangle; policy accept;
            iifname { "bond0.10", "bond0.20", "bond0.100", "bond0.3001", "wg01" } meta nfproto ipv4 udp dport 69 ct helper set "tftp"
          }
          chain input {
            type filter hook input priority filter; policy drop;
            iifname "lo" accept
            ct state invalid drop
            ct state established,related accept
            # DHCP client bootstrap; VyOS installed these outside its zone rules.
            iifname "wan0" udp sport 67 udp dport 68 accept
            iifname "wan0" udp sport 547 udp dport 546 accept
            # Node exporter now runs natively, using the actual loopback identity.
            iifname "bond0.3001" ip saddr 172.20.0.0/16 ip daddr 10.254.254.1 tcp dport 9100 accept
            ${dispatch "input"}
          }
          chain forward {
            type filter hook forward priority filter; policy drop;
            ct state invalid drop
            ct state established,related accept
            # VyOS allows forwarding within a zone, including WireGuard -> trusted.
            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList (_: ifs: "iifname ${interfaces ifs} oifname ${interfaces ifs} accept") zones
            )}
            ${dispatch "forward"}
          }
          chain output {
            type filter hook output priority filter; policy drop;
            oifname "lo" accept
            ct state invalid drop
            ct state established,related accept
            # DHCP/RA are emitted by networkd rather than VyOS service bypass rules.
            oifname "wan0" udp sport { 68, 546 } udp dport { 67, 547 } accept
            oifname { "bond0.10", "bond0.20", "bond0.30", "bond0.40", "bond0.100" } udp sport 67 udp dport 68 accept
            oifname { "bond0.20", "bond0.40" } meta l4proto ipv6-icmp accept
            # Kernel log collector is routed through transit, not the servers VLAN.
            oifname "bond0.3001" ip daddr 10.45.0.2 tcp dport 6001 accept
            ${dispatch "output"}
          }
          chain mss {
            type filter hook forward priority mangle; policy accept;
            tcp flags & (syn | rst) == syn tcp option maxseg size set rt mtu
          }
          chain prerouting {
            type nat hook prerouting priority dstnat; policy accept;
            iifname { "bond0.40", "wg01" } ip daddr != 172.53.53.53 meta l4proto { tcp, udp } th dport 53 dnat ip to 172.53.53.53
            iifname { "bond0.20", "bond0.40" } ip6 daddr != fd74:f571:d3bd:53::53 meta l4proto { tcp, udp } th dport 53 dnat ip6 to fd74:f571:d3bd:53::53
            # Fix the old bond0 match: management is actually on VLAN 100.
            iifname { "bond0.100", "bond0.10", "bond0.20", "bond0.40", "wg01" } ip daddr != 10.254.254.1 udp dport 123 dnat ip to 10.254.254.1
            iifname "wan0" tcp dport 59453 dnat ip to 10.1.2.60:59453
            iifname "wan0" tcp dport 50413 dnat ip to 10.45.0.24:50413
          }
          chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;
            oifname "wan0" meta nfproto ipv4 masquerade
          }
        '';
    };
  };
}
