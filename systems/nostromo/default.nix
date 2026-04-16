{ lib, ... }:
let
  # Replace these before deployment. The /31 is the routed underlay
  # attachment, the /32 is the stable routing identity.
  bondAddress = "192.0.2.0/31";
  routerIdAddress = "198.51.100.10/32";
in
{
  imports = [
    ./disk-config.nix
    ./nas.nix
  ];

  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.grub = {
    enable = true;
    efiInstallAsRemovable = true;
    efiSupport = true;
    mirroredBoots = [
      {
        path = "/boot";
      }
      {
        path = "/boot-fallback";
      }
    ];
  };
  boot.loader.systemd-boot.enable = lib.mkForce false;

  networking.hostName = "nostromo";
  networking.useDHCP = false;

  systemd.network = {
    enable = true;
    netdevs."10-bond0" = {
      netdevConfig = {
        Kind = "bond";
        Name = "bond0";
      };
      bondConfig = {
        Mode = "802.3ad";
        LACPTransmitRate = "fast";
        MIIMonitorSec = "1s";
        TransmitHashPolicy = "layer3+4";
      };
    };
    netdevs."20-bird0" = {
      netdevConfig = {
        Kind = "dummy";
        Name = "bird0";
      };
    };
    networks."10-bond0" = {
      matchConfig.Name = "bond0";
      address = [ bondAddress ];
      networkConfig = {
        DHCP = "no";
        LinkLocalAddressing = "no";
      };
    };
    networks."20-bird0" = {
      matchConfig.Name = "bird0";
      address = [ routerIdAddress ];
      networkConfig = {
        ConfigureWithoutCarrier = true;
        DHCP = "no";
        LinkLocalAddressing = "no";
      };
    };
    networks."10-mlx5" = {
      matchConfig.Driver = "mlx5_core";
      networkConfig = {
        Bond = "bond0";
        DHCP = "no";
      };
    };
  };

  system.stateVersion = "25.11";
}
