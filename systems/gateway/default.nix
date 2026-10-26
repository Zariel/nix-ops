{ ... }:
{
  imports = [
    ./hardware.nix
    ./network.nix
    ./secrets.nix
    ./firewall.nix
    ./dhcp.nix
    ./services.nix
    ./qos.nix
  ];
  networking.hostName = "gateway";
  networking.domain = "cbannister.casa";
  system.stateVersion = "26.05";
  # Updates are deliberate maintenance operations on the only router.
  system.autoUpgrade.enable = false;
}
