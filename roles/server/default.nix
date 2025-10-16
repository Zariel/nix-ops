{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Networking defaults
  networking.firewall.enable = false;
  networking.networkmanager.enable = false;
}
