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
  ];

  # Bootloader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 0;
    };

    plymouth = {
      enable = true;
      theme = "rings";
      themePackages = with pkgs; [
        # By default we would install all themes
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "rings" ];
        })
      ];
    };

    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "intel_idle.max_cstate=1"
      "processor.max_cstate=1"
      "split_lock_detect=off"
      # "amdgpu.freesync_video=1" # Enable FreeSync for video playback
      "amdgpu.dc=1" # Explicitly enable Display Core (required for DSC)
      # "amdgpu.dc_log=1"  # Uncomment to enable verbose DC debug logging

      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
      "amdgpu.seamless=1"
    ];

    kernel.sysctl = {
      "vm.max_map_count" = 2147483642; # Required for many modern games
      "fs.file-max" = 524288; # Increase file descriptor limit
    };
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
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "gaming"; # Define your hostname.

  networking.firewall.enable = false;

  # Enable networking
  networking.networkmanager.enable = true;

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

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    # X11 VRR fallback configuration (Wayland has native VRR support)
    deviceSection = ''
      Option "VariableRefresh" "true"
      Option "TearFree" "false"
    '';
  };

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true; # Enable Wayland for better VRR support
  };
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "gb";
    variant = "mac";
    model = "pc105";
  };

  # Configure console keymap
  console.keyMap = "uk";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  security.pam.yubico = {
    enable = true;
    id = "18293395";
  };

  services.fwupd.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
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
      "gamemode"
    ];
    shell = pkgs.fish;
    packages = with pkgs; [
      kdePackages.kate
      #  thunderbird
    ];
  };

  programs.fish.enable = true;

  # Install firefox.
  programs.firefox = {
    enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    protontricks.enable = true;
    extraPackages = with pkgs; [
      gamemode
    ];
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
      };
    };
  };

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = [ "chris" ];
  };

  hardware.graphics = {
    enable = lib.mkDefault true;
    enable32Bit = lib.mkDefault true;
  };

  hardware.amdgpu.initrd.enable = lib.mkDefault true;

  boot.loader.systemd-boot.memtest86.enable = true;

  # Make Intel RAPL power usage readable for mangohud
  systemd.services.make-rapl-readable = {
    description = "Make Intel RAPL energy counter readable";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/chmod 444 /sys/class/powercap/intel-rapl:0/energy_uj";
      RemainAfterExit = true;
    };
  };

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
    cups-brother-mfcl2800dw
    nfs-utils
    mesa
    libdrm
    # inputs.nixpkgs-gamma.legacyPackages.${pkgs.system}.gamma-launcher
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
  ];

  # AMD GPU optimizations and gaming environment
  environment.sessionVariables = {
    RADV_PERFTEST = "gpl,nggc"; # Enable GPL shader compilation and NGG culling
    AMD_VULKAN_ICD = "RADV"; # Use RADV driver
    MANGOHUD = "1"; # Enable MangoHud for all games by default
  };

  home-manager.backupFileExtension = "backup";

  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true; # needed for NFS

  systemd.mounts = [
    {
      type = "nfs";
      mountConfig = {
        Options = "noatime";
      };
      what = "nas.cbannister.casa:/mnt/bighorse/arr";
      where = "/mnt/bighorse/arr";
    }
  ];

  systemd.automounts = [
    {
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      where = "/mnt/bighorse/arr";
    }
  ];

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
