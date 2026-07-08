{ lib, pkgs, ... }:
let
  rootDiskA = "/dev/disk/by-id/ata-SAMSUNG_MZ7L3480HCHQ-00A07_S664NT0X604542";
  rootDiskB = "/dev/disk/by-id/ata-SAMSUNG_MZ7L3480HCHQ-00A07_S664NT0X604546";
in
{
  boot.swraid.mdadmConf = "PROGRAM ${pkgs.coreutils}/bin/true";

  disko.devices = {
    disk.root-a = {
      device = lib.mkDefault rootDiskA;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            name = "nostromo-boot-a";
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            name = "nostromo-root-a";
            size = "100%";
            content = {
              type = "mdraid";
              name = "root";
            };
          };
        };
      };
    };

    disk.root-b = {
      device = lib.mkDefault rootDiskB;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            name = "nostromo-boot-b";
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot-fallback";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            name = "nostromo-root-b";
            size = "100%";
            content = {
              type = "mdraid";
              name = "root";
            };
          };
        };
      };
    };

    mdadm.root = {
      type = "mdadm";
      level = 1;
      content = {
        type = "filesystem";
        format = "xfs";
        mountpoint = "/";
        mountOptions = [
          "defaults"
          "noatime"
        ];
      };
    };
  };
}
