{
  ...
}:
{
  imports = [ ./vector.nix ];

  # Networking defaults
  networking.firewall.enable = false;
  networking.networkmanager.enable = false;
  services.resolved.enable = true;
}
