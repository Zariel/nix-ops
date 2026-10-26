{ lib, ... }:
let
  vlans = {
    "10" = {
      addresses = [ "10.1.1.1/24" ];
      mtu = 9000;
    };
    "20" = {
      addresses = [
        "10.1.2.1/24"
        "fd74:f571:d3bd:20::1/64"
      ];
      mtu = 1500;
    };
    "30" = {
      addresses = [ "192.168.2.1/24" ];
      mtu = 1500;
    };
    "40" = {
      addresses = [
        "10.1.3.1/24"
        "fd74:f571:d3bd:40::1/64"
      ];
      mtu = 1500;
    };
    "100" = {
      addresses = [ "10.1.0.1/24" ];
      mtu = 1500;
    };
    "3001" = {
      addresses = [ "10.254.0.0/31" ];
      mtu = 9000;
    };
  };
  macs = {
    lan0 = "08:c0:eb:0f:e4:30";
    lan1 = "08:c0:eb:0f:e4:31";
    spare0 = "a0:36:9f:a9:0d:3a";
    wan0 = "a0:36:9f:a9:0d:3b";
    rescue0 = "50:9a:4c:4b:f6:0c";
  };
in
{
  networking.useDHCP = false;
  networking.networkmanager.enable = false;
  networking.nameservers = [
    "1.1.1.1"
    "2606:4700:4700::1111"
  ];
  services.resolved.enable = true;
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.ip_forward_use_pmtu" = 1;
    "net.ipv4.tcp_mtu_probing" = 1;
  };
  systemd.network = {
    enable = true;
    # Unplugged spare interfaces and absent WAN must not stall boot.
    wait-online.enable = false;
    config.networkConfig = {
      ManageForeignRoutes = false;
      ManageForeignRoutingPolicyRules = false;
      ManageForeignNextHops = false;
    };
    links = lib.mapAttrs' (
      name: mac:
      lib.nameValuePair "10-${name}" {
        matchConfig.PermanentMACAddress = mac;
        linkConfig.Name = name;
      }
    ) macs;
    netdevs = {
      "20-bond0" = {
        netdevConfig = {
          Name = "bond0";
          Kind = "bond";
          MACAddress = macs.lan0;
          MTUBytes = "9000";
        };
        bondConfig = {
          Mode = "802.3ad";
          TransmitHashPolicy = "layer3+4";
          LACPTransmitRate = "fast";
          MIIMonitorSec = "100ms";
        };
      };
      "20-containers".netdevConfig = {
        Name = "pod-containers";
        Kind = "bridge";
      };
      "20-dum99".netdevConfig = {
        Name = "dum99";
        Kind = "dummy";
      };
      "20-ifb0".netdevConfig = {
        Name = "ifb0";
        Kind = "ifb";
      };
      "20-wg01" = {
        netdevConfig = {
          Name = "wg01";
          Kind = "wireguard";
          MTUBytes = "1420";
        };
        wireguardConfig = {
          ListenPort = 51820;
          # PrivateKeyFile is supplied by secrets.nix through sops-nix.
        };
        wireguardPeers = [
          {
            PublicKey = "0wrH9QqKMRbcnMc41xzwEvLX9xyKY/mB1no94woOAhQ=";
            AllowedIPs = [ "10.0.11.4/32" ];
            PersistentKeepalive = 15;
          }
          {
            PublicKey = "YDJXbNWbwqA7ipjuVaBrR83Yp6DXocojiFigEIUJnVk=";
            AllowedIPs = [ "10.0.11.5/32" ];
            PersistentKeepalive = 15;
          }
          {
            PublicKey = "8GJVX0GvW7BE8n+G1+Be/IlvJx5rMQyno5bG8iIK1EY=";
            AllowedIPs = [ "10.0.11.6/32" ];
            PersistentKeepalive = 15;
          }
        ];
      };
    }
    // lib.mapAttrs' (
      id: vlan:
      lib.nameValuePair "30-vlan${id}" {
        netdevConfig = {
          Name = "bond0.${id}";
          Kind = "vlan";
          MTUBytes = toString vlan.mtu;
        };
        vlanConfig.Id = lib.toInt id;
      }
    ) vlans;
    networks = {
      "10-loopback" = {
        matchConfig.Name = "lo";
        address = [ "10.254.254.1/32" ];
      };
      "20-bond-members" = {
        matchConfig.Name = "lan0 lan1";
        networkConfig = {
          Bond = "bond0";
          LinkLocalAddressing = "no";
        };
        linkConfig = {
          MTUBytes = "9000";
          RequiredForOnline = "no";
        };
      };
      "30-bond" = {
        matchConfig.Name = "bond0";
        vlan = map (id: "bond0.${id}") (builtins.attrNames vlans);
        networkConfig = {
          LinkLocalAddressing = "ipv6";
          IPv6AcceptRA = false;
        };
      };
      "30-wan" = {
        matchConfig.Name = "wan0";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
        dhcpV4Config = {
          UseDNS = false;
          UseNTP = false;
          ClientIdentifier = "mac";
          RouteMetric = 100;
        };
        dhcpV6Config = {
          UseDNS = false;
          UseNTP = false;
          PrefixDelegationHint = "::/56";
          WithoutRA = "solicit";
          RapidCommit = true;
        };
        ipv6AcceptRAConfig = {
          UseDNS = false;
          UseDomains = false;
        };
      };
      "30-spares" = {
        matchConfig.Name = "spare0 rescue0";
        networkConfig = {
          DHCP = "no";
          LinkLocalAddressing = "no";
          IPv6AcceptRA = false;
        };
        linkConfig.RequiredForOnline = "no";
      };
      "30-wg01" = {
        matchConfig.Name = "wg01";
        address = [ "10.0.11.1/24" ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6AcceptRA = false;
        };
      };
      "30-dum99" = {
        matchConfig.Name = "dum99";
        networkConfig = {
          DHCPPrefixDelegation = true;
          ConfigureWithoutCarrier = true;
          IPv6AcceptRA = false;
        };
        dhcpPrefixDelegationConfig = {
          UplinkInterface = "wan0";
          SubnetId = "0x63";
          Announce = false;
          Assign = true;
          Token = "::1";
        };
      };
      "30-ifb0" = {
        matchConfig.Name = "ifb0";
        networkConfig = {
          ConfigureWithoutCarrier = true;
          LinkLocalAddressing = "no";
        };
      };
      "30-containers" = {
        matchConfig.Name = "pod-containers";
        address = [
          "10.5.0.1/24"
          "fd74:f571:d3bd:1005::1/64"
        ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6AcceptRA = false;
        };
      };
    }
    // lib.mapAttrs' (
      id: vlan:
      lib.nameValuePair "40-vlan${id}" (
        {
          matchConfig.Name = "bond0.${id}";
          address = vlan.addresses;
          networkConfig.IPv6AcceptRA = false;
        }
        //
          lib.optionalAttrs
            (builtins.elem id [
              "20"
              "40"
            ])
            {
              networkConfig = {
                IPv6AcceptRA = false;
                IPv6SendRA = true;
              };
              ipv6SendRAConfig = {
                DNS = [ "fd74:f571:d3bd:53::53" ];
                RouterPreference = "high";
              };
              ipv6Prefixes = [ { Prefix = "fd74:f571:d3bd:${id}::/64"; } ];
              ipv6RoutePrefixes = [ { Route = "fd74:f571:d3bd::/48"; } ];
            }
      )
    ) vlans;
  };
}
