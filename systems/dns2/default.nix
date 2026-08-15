{ ... }:
{
  imports = [
    ./configuration.nix
    ./hardware.nix
    ../../roles/dnsVip
  ];

  services.dnsVip = {
    enable = true;
    nodeIp = "10.254.53.2";
    bgpPeerIp = "10.254.53.3";
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
  };
}
