{ lib, ... }:
let
  gatewayAddress = "10.254.1.100";
  uplinkAddress = "10.254.1.101/31";
in
{
  imports = [
    ./disk-config.nix
    ./nas.nix
  ];

  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    efiInstallAsRemovable = true;
    efiSupport = true;
    mirroredBoots = [
      {
        devices = [ "nodev" ];
        path = "/boot";
      }
      {
        devices = [ "nodev" ];
        path = "/boot-fallback";
      }
    ];
  };
  boot.loader.systemd-boot.enable = lib.mkForce false;

  networking.hostName = "nostromo";
  networking.nameservers = [
    "172.53.53.53"
    "1.1.1.1"
    "8.8.8.8"
  ];
  networking.useDHCP = false;

  systemd.network = {
    enable = true;
    networks."10-uplink" = {
      matchConfig.Name = "enp5s0np1";
      address = [ uplinkAddress ];
      dns = [
        "172.53.53.53"
        "1.1.1.1"
        "8.8.8.8"
      ];
      gateway = [ gatewayAddress ];
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = false;
        LinkLocalAddressing = "ipv6";
      };
      linkConfig = {
        MTUBytes = "9000";
      };
    };
  };

  system.stateVersion = "26.05";
}
