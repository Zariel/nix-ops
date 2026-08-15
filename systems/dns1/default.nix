{ ... }:
{
  imports = [
    ./configuration.nix
    ./hardware.nix
    ../../roles/dnsVip
  ];

  services.dnsVip = {
    enable = true;
    nodeIp = "10.254.53.0";
    bgpPeerIp = "10.254.53.1";
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
  };
}
