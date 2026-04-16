{
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "fastpool" ];
  boot.zfs.devNodes = "/dev/disk/by-id";

  networking.hostId = "6e6f7374";

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };
}
