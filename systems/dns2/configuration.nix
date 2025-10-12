{ ... }:
{
  networking.hostName = "dns-2";

  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "ens*";
      address = [ "10.1.53.11/24" ];
      gateway = [ "10.1.53.1" ];
      dns = [ "1.1.1.1" ];
    };
  };

  services.qemuGuest.enable = true;
}
