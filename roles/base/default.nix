{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Nix settings
  nix.settings = {
    auto-optimise-store = true;
    trusted-users = [
      "root"
      "chris"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Binary cache settings
    substituters = lib.mkAfter [
      "http://10.1.1.155:5000"
      "https://nix-community.cachix.org"
      "https://nixpkgs-unfree.cachix.org"
      "https://cachix.cachix.org"
      "https://cache.garnix.io"
    ];

    trusted-public-keys = lib.mkAfter [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
      "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "cache-name:nKgRvz/pXDZWsXAuzXcoRyyW2Ryut5EpoeLEeiyqgnA="
    ];
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # Locale and timezone
  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Keyboard configuration
  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };
  console.keyMap = "uk";

  # User configuration
  users.users.chris = {
    isNormalUser = true;
    description = "chris";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINiFPVXT03FdYS3BKuqNmgplaGrzNc6i++77vCI2AJ8c id_ed25519"
    ];
  };

  # Security
  security.sudo.wheelNeedsPassword = false;

  # Base packages
  environment.systemPackages = with pkgs; [
    helix
    sudo
    nh
    htop
    btop
    git
    smartmontools
  ];

  programs.direnv.enable = true;
  programs.fish.enable = lib.mkDefault true;

  # Services
  services.openssh.enable = true;
  services.prometheus.exporters.node.enable = true;
  services.resolved.enable = true;

  # State version
  system.stateVersion = "25.05";
}
