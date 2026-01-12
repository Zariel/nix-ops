# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [
  ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642; # Required for many modern games
    "fs.file-max" = 524288; # Increase file descriptor limit
  };

  hardware.cpu.intel.updateMicrocode = true;

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "builder.cbannister.casa";
        system = "x86_64-linux";
        sshUser = "chris";
        protocol = "ssh";
        maxJobs = 4; # Limit remote jobs to match builder capacity
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
      # Local build parallelism - with 20 cores, run multiple builds locally too
      max-jobs = 8; # Run up to 8 builds in parallel (local + remote combined)
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

  # Use latest kernel.
  networking.hostName = "dev"; # Define your hostname.

  networking.firewall.enable = false;

  # Enable networking
  # networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
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

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.chris = {
    isNormalUser = true;
    description = "chris";
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

  services.qemuGuest.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    helix
    nil
    htop
    btop
    iotop
    lm_sensors
    pciutils
    gcc
    linux-firmware
    file
    lsof
    usbutils
    fio
    nfs-utils
    # inputs.nixpkgs-gamma.legacyPackages.${pkgs.system}.gamma-launcher
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
  ];

  environment.sessionVariables = {
  };

  home-manager.backupFileExtension = "backup";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
