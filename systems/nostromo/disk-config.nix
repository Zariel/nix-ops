{ lib, ... }:
let
  # Replace these with the actual stable by-id values before running nix-anywhere.
  rootDiskA = "/dev/disk/by-id/ata-ROOT_SSD_A";
  rootDiskB = "/dev/disk/by-id/ata-ROOT_SSD_B";
  fastDiskA = "/dev/disk/by-id/nvme-FAST_NVME_A";
  fastDiskB = "/dev/disk/by-id/nvme-FAST_NVME_B";
in
{
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
          zfs = {
            name = "nostromo-rpool-a";
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool";
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
          zfs = {
            name = "nostromo-rpool-b";
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };
    };

    disk.fast-a = {
      device = lib.mkDefault fastDiskA;
      type = "disk";
      content = {
        type = "gpt";
        partitions.zfs = {
          name = "nostromo-fastpool-a";
          size = "100%";
          content = {
            type = "zfs";
            pool = "fastpool";
          };
        };
      };
    };

    disk.fast-b = {
      device = lib.mkDefault fastDiskB;
      type = "disk";
      content = {
        type = "gpt";
        partitions.zfs = {
          name = "nostromo-fastpool-b";
          size = "100%";
          content = {
            type = "zfs";
            pool = "fastpool";
          };
        };
      };
    };

    zpool.rpool = {
      type = "zpool";
      mode = "mirror";
      options = {
        ashift = "12";
        autotrim = "on";
      };
      rootFsOptions = {
        acltype = "posixacl";
        atime = "off";
        compression = "zstd";
        dnodesize = "auto";
        mountpoint = "none";
        normalization = "formD";
        primarycache = "metadata";
        xattr = "sa";
      };
      datasets = {
        root = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };
        "root/nixos" = {
          type = "zfs_fs";
          mountpoint = "/";
          options = {
            canmount = "noauto";
            mountpoint = "legacy";
          };
        };
        home = {
          type = "zfs_fs";
          mountpoint = "/home";
          options.mountpoint = "legacy";
        };
      };
    };

    zpool.fastpool = {
      type = "zpool";
      mode = "mirror";
      options = {
        ashift = "12";
        autotrim = "on";
      };
      rootFsOptions = {
        acltype = "posixacl";
        atime = "off";
        compression = "zstd";
        mountpoint = "none";
        primarycache = "metadata";
        xattr = "sa";
      };
      datasets = {
        nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
          options = {
            atime = "off";
            mountpoint = "legacy";
          };
        };
        local-storage = {
          type = "zfs_fs";
          mountpoint = "/var/lib/local-storage";
          options.mountpoint = "legacy";
        };
      };
    };
  };
}
