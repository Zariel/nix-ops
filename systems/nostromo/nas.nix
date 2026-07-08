{
  boot.supportedFilesystems = [
    "xfs"
    "zfs"
  ];
  boot.zfs.extraPools = [ "bighorse" ];
  boot.zfs.devNodes = "/dev/disk/by-id";

  networking.hostId = "6e6f7374";

  services.nfs = {
    server = {
      enable = true;
      exports = ''
        "/mnt/bighorse/arr" 10.0.0.0/8(sec=sys,rw,no_root_squash,insecure,no_subtree_check) 192.168.254.0/24(sec=sys,rw,no_root_squash,insecure,no_subtree_check)
        "/mnt/bighorse/pve" 10.0.0.0/8(sec=sys,rw,insecure,no_subtree_check)
        "/mnt/bighorse/volsync" 10.0.0.0/8(sec=sys,rw,no_root_squash,insecure,no_subtree_check)
        "/mnt/bighorse/music/downloads" 10.0.0.0/8(sec=sys,rw,anonuid=568,anongid=3005,all_squash,insecure,no_subtree_check) 192.168.254.0/24(sec=sys,rw,anonuid=568,anongid=3005,all_squash,insecure,no_subtree_check)
        "/mnt/bighorse/incompletes" 10.0.0.0/8(sec=sys,rw,no_root_squash,insecure,no_subtree_check)
        "/mnt/bighorse/Photos/Immich" 10.0.0.0/8(sec=sys,rw,no_root_squash,insecure,no_subtree_check)
      '';
      nproc = 256;
    };
    settings.nfsd = {
      vers3 = false;
      vers4 = true;
    };
  };

  services.samba = {
    enable = true;
    nmbd.enable = true;
    openFirewall = true;
    winbindd.enable = false;
    settings = {
      global = {
        "create mask" = "0664";
        "directory mask" = "0775";
        "disable spoolss" = "yes";
        "dns proxy" = "no";
        "fruit:metadata" = "stream";
        "fruit:resource" = "stream";
        "invalid users" = [ "root" ];
        "load printers" = "no";
        "netbios name" = "NOSTROMO";
        "ntlm auth" = "disabled";
        "printcap name" = "/dev/null";
        "restrict anonymous" = 2;
        "security" = "user";
        "server min protocol" = "SMB2_02";
        "server string" = "TrueNAS Server";
        "smbd max xattr size" = 2097152;
        "vfs objects" = "fruit streams_xattr acl_xattr";
        "workgroup" = "WORKGROUP";
      };
      lidarr = {
        "comment" = "lidarr managed music";
        "guest ok" = "no";
        "path" = "/mnt/bighorse/music/lidarr";
        "posix locking" = "no";
        "read only" = "no";
      };
      music = {
        "comment" = "Roon Music source";
        "guest ok" = "no";
        "path" = "/mnt/bighorse/music/library";
        "posix locking" = "no";
        "read only" = "no";
      };
      "music.downloads" = {
        "guest ok" = "no";
        "level2 oplocks" = "no";
        "oplocks" = "no";
        "path" = "/mnt/bighorse/music/downloads";
        "read only" = "no";
      };
      "roon-backups" = {
        "guest ok" = "no";
        "path" = "/mnt/bighorse/backups/roon";
        "posix locking" = "no";
        "read only" = "no";
      };
      sharing = {
        "guest ok" = "no";
        "path" = "/mnt/bighorse/sharing";
        "posix locking" = "no";
        "read only" = "no";
      };
      "torrents.shared" = {
        "browseable" = "no";
        "guest ok" = "no";
        "level2 oplocks" = "no";
        "oplocks" = "no";
        "path" = "/mnt/bighorse/arr/downloads/torrents/complete/shared";
        "read only" = "no";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    hostname = "NOSTROMO";
    openFirewall = true;
    workgroup = "WORKGROUP";
  };

  services.fstrim.enable = true;

  systemd.services.nfs-mountd = {
    after = [ "zfs-mount.service" ];
    requires = [ "zfs-mount.service" ];
  };
  systemd.services.nfs-server = {
    after = [ "zfs-mount.service" ];
    requires = [ "zfs-mount.service" ];
  };
  systemd.services.samba-smbd = {
    after = [ "zfs-mount.service" ];
    requires = [ "zfs-mount.service" ];
  };

  users.groups.apps.gid = 568;
  users.groups.chris.gid = 3002;
  users.groups.shared.gid = 3005;
  users.users.chris = {
    group = "chris";
    uid = 3001;
  };
  users.users.apps = {
    extraGroups = [ "shared" ];
    group = "apps";
    isSystemUser = true;
    uid = 568;
  };

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };
}
