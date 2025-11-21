{ ... }:
{
  networking.hostName = "dns-2";
  networking.useDHCP = false;

  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "ens*";
      address = [ "10.254.53.2/31" ];
      gateway = [ "10.254.53.3" ];
      dns = [ "1.1.1.1" ];

      networkConfig = {
        IPv6AcceptRA = true;
      };
    };
  };

  services.qemuGuest.enable = true;
}
