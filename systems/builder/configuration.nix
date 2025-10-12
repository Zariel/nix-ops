{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "nix-builder";
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "ens*";
      address = [ "10.1.1.155/24" ];
      gateway = [ "10.1.1.1" ];
      dns = [ "10.5.0.4" ];
    };
  };

  # Builder-specific nix settings
  nix.settings = {
    min-free = lib.mkDefault (1024 * 1024 * 1024); # 1GB
    max-free = lib.mkDefault (5 * 1024 * 1024 * 1024); # 5GB
  };

  # Additional SSH key for nix-daemon
  users.users.chris.openssh.authorizedKeys.keys = lib.mkAfter [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+Nua2Ygsk93Z3aybi+cxuqGjkK6tbP+3rVj6k39RpQ nix-daemon@macbook"
  ];

  # Builder-specific packages
  environment.systemPackages = with pkgs; [
    neovim
  ];

  services.qemuGuest.enable = true;

  # Binary cache service
  services.harmonia = {
    enable = true;
    signKeyPaths = [ "/var/lib/secrets/harmonia-key" ];
    settings = {
      bind = "0.0.0.0:5000";
    };
  };
}
