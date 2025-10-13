{ ... }:
{
  networking.hostName = "dns-1";
  networking.useDHCP = false;

  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "ens*";
      address = [ "10.1.53.10/24" ];
      gateway = [ "10.1.53.1" ];
      dns = [ "1.1.1.1" ];

      networkConfig = {
        IPv6AcceptRA = true;
      };
    };
  };

  services.qemuGuest.enable = true;
}
