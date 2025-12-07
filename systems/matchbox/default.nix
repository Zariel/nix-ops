{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./pxe.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "matchbox";
    useDHCP = false;
  };

  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "ens*";
      networkConfig.DHCP = "ipv4";
    };
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  # Additional SSH key for nix-daemon
  users.users.chris.openssh.authorizedKeys.keys = lib.mkAfter [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+Nua2Ygsk93Z3aybi+cxuqGjkK6tbP+3rVj6k39RpQ nix-daemon@macbook"
  ];

  # Builder-specific packages
  environment.systemPackages = with pkgs; [
    helix
    doggo
  ];

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "builder.cbannister.casa";
        system = "x86_64-linux";
        sshUser = "chris";
        protocol = "ssh";
        maxJobs = 10; # Limit remote jobs to match builder capacity
        speedFactor = 2; # Prefer remote builder (higher = more preferred)
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
      }
    ];

    settings = {
      max-jobs = "auto"; # Run up to 8 builds in parallel (local + remote combined)
      cores = 0; # Let each build use all available cores (auto-detected)
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
  };

  services.qemuGuest.enable = true;
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

  users.users.chris = {
    isNormalUser = true;
    description = "chris";
    initialPassword = "anthem";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.fish;
    packages = with pkgs; [
    ];
  };

  programs.fish.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.11"; # Did you read the comment?
}
