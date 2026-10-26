{ pkgs, ... }:
{
  services.frr = {
    bgpd.enable = true;
    pimd.enable = true;
    pim6d.enable = true;
    config = builtins.readFile ./frr.conf;
  };
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };
  services.chrony = {
    enable = true;
    servers = [
      "0.uk.pool.ntp.org"
      "1.uk.pool.ntp.org"
      "2.uk.pool.ntp.org"
      "3.uk.pool.ntp.org"
    ];
    extraConfig = ''
      bindaddress 10.254.254.1
      allow 127.0.0.0/8
      allow 10.0.0.0/8
      allow 172.16.0.0/12
      allow 192.168.0.0/16
    '';
  };
  services.rsyslogd = {
    enable = true;
    defaultConfig = ""; # journald remains the local log store
    extraConfig = ''
      kern.warning action(type="omfwd" target="10.45.0.2" port="6001"
        protocol="tcp" TCP_Framing="octet-counted" template="RSYSLOG_SyslogProtocol23Format"
        action.resumeRetryCount="-1" queue.type="LinkedList" queue.size="10000")
    '';
  };
  services.avahi = {
    enable = true;
    allowInterfaces = [
      "bond0.20"
      "bond0.40"
    ];
    reflector = true;
    openFirewall = false;
    extraConfig = ''
      reflect-filters=_hap._tcp.local,_hap._udp.local,_airplay._tcp.local,_raop._tcp.local,_ipp._tcp.local,_printer._tcp.local,_companion-link._tcp.local,_meshcop._udp.local,_matterc._udp.local,_matter._tcp.local,_matterd._udp.local
    '';
  };
  # Keep the existing application versions and on-disk state for the OS migration.
  # Podman only attaches veths; networkd owns the bridge and nftables owns policy/NAT.
  virtualisation.podman.enable = true;
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      matchbox = {
        image = "quay.io/poseidon/matchbox:v0.11.0";
        cmd = [
          "-address=0.0.0.0:80"
          "-log-level=info"
        ];
        extraOptions = [
          "--network=gateway-apps"
          "--ip=10.5.0.8"
          "--cap-add=NET_BIND_SERVICE"
        ];
        volumes = [ "/var/lib/gateway/matchbox:/var/lib/matchbox" ];
      };
      unifi = {
        image = "ghcr.io/goofball222/unifi:9.5.21";
        extraOptions = [
          "--network=gateway-apps"
          "--ip=10.5.0.10"
        ];
        environment = {
          TZ = "Europe/London";
          RUNAS_UID0 = "false";
          PGID = "102";
          PUID = "999";
        };
        volumes = [
          "/var/lib/gateway/unifi/cert:/usr/lib/unifi/cert"
          "/var/lib/gateway/unifi/data:/usr/lib/unifi/data"
          "/var/lib/gateway/unifi/logs:/usr/lib/unifi/logs"
        ];
      };
      speedtest-exporter = {
        image = "ghcr.io/miguelndecarvalho/speedtest-exporter:v3.5.4";
        extraOptions = [ "--network=host" ];
      };
    };
  };
  systemd.services.gateway-app-network = {
    description = "Podman attachment to the networkd application bridge";
    requires = [ "sys-subsystem-net-devices-pod\\x2dcontainers.device" ];
    after = [ "sys-subsystem-net-devices-pod\\x2dcontainers.device" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Fixed topology: --ignore deliberately does not mutate a network with live containers.
      ExecStart = "${pkgs.podman}/bin/podman network create --ignore --disable-dns --interface-name=pod-containers --opt=mode=unmanaged --subnet=10.5.0.0/24 --gateway=10.5.0.1 --ipv6 --subnet=fd74:f571:d3bd:1005::/64 --gateway=fd74:f571:d3bd:1005::1 gateway-apps";
    };
  };
  systemd.services.podman-matchbox = {
    requires = [ "gateway-app-network.service" ];
    after = [ "gateway-app-network.service" ];
  };
  systemd.services.podman-unifi = {
    requires = [ "gateway-app-network.service" ];
    after = [ "gateway-app-network.service" ];
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/gateway 0750 root systemd-network -"
    "d /var/lib/gateway/matchbox 0755 root root -"
    "d /var/lib/gateway/unifi 0755 root root -"
  ];
  environment.systemPackages = with pkgs; [
    tcpdump
    conntrack-tools
    wireguard-tools
  ];
}
