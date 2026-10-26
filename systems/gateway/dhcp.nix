{ config, lib, ... }:
let
  reservations = import ./reservations.nix;
  hosts = lib.concatStringsSep "\n" (
    lib.concatLists (
      lib.mapAttrsToList (
        zone: entries:
        lib.mapAttrsToList (
          name: values: "${builtins.elemAt values 0},set:${zone},${builtins.elemAt values 1},${name}"
        ) entries
      ) reservations
    )
  );
in
{
  environment.etc."gateway/dhcp-hosts".text = hosts + "\n";
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
      port = 0;
      bind-dynamic = true;
      interface = [
        "bond0.10"
        "bond0.20"
        "bond0.30"
        "bond0.40"
        "bond0.100"
        "bond0.3001"
        "wg01"
      ];
      dhcp-authoritative = true;
      dhcp-hostsfile = "/etc/gateway/dhcp-hosts";
      dhcp-range = [
        "set:servers,10.1.1.200,10.1.1.254,255.255.255.0,8h"
        "set:trusted,10.1.2.200,10.1.2.254,255.255.255.0,8h"
        "set:guest,192.168.2.200,192.168.2.254,255.255.255.0,1h"
        "set:iot,10.1.3.200,10.1.3.254,255.255.255.0,8h"
        "set:lan,10.1.0.200,10.1.0.254,255.255.255.0,8h"
      ];
      dhcp-option = [
        "option:dns-server,172.53.53.53"
        "tag:servers,option:router,10.1.1.1"
        "tag:trusted,option:router,10.1.2.1"
        "tag:guest,option:router,192.168.2.1"
        "tag:iot,option:router,10.1.3.1"
        "tag:lan,option:router,10.1.0.1"
        "tag:servers,option:ntp-server,10.254.254.1"
        "tag:trusted,option:ntp-server,10.254.254.1"
        "tag:lan,option:ntp-server,10.254.254.1"
        "tag:servers,option:domain-name,cbannister.casa"
        "tag:trusted,option:domain-name,cbannister.casa"
        "tag:iot,option:domain-name,cbannister.casa"
        "tag:lan,vendor:ubnt,1,10.5.0.10"
      ];
      dhcp-userclass = "set:ipxe,iPXE";
      dhcp-match = [
        "set:efi,option:client-arch,7"
        "set:efi,option:client-arch,9"
      ];
      dhcp-boot = [
        "tag:servers,tag:ipxe,http://10.5.0.8/boot.ipxe"
        "tag:servers,tag:!ipxe,tag:efi,ipxe.efi,,10.1.1.1"
        "tag:servers,tag:!ipxe,tag:!efi,undionly.kpxe,,10.1.1.1"
      ];
      enable-tftp = true;
      no-dhcp-interface = [
        "bond0.3001"
        "wg01"
      ];
      tftp-root = "/var/lib/tftpboot";
      tftp-secure = true;
    };
  };
  # Only reservation changes use SIGHUP. Main config changes still restart dnsmasq:
  # SIGHUP does NOT reread its main configuration file.
  systemd.services.dnsmasq.reloadTriggers = [ config.environment.etc."gateway/dhcp-hosts".source ];
  systemd.tmpfiles.rules = [ "d /var/lib/tftpboot 0755 dnsmasq dnsmasq -" ];
}
