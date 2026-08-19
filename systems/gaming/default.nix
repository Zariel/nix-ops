# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  ...
}:

let
  gamemodeSteamCompat = import ./pkgs/gamemode-steam-compat.nix { inherit pkgs; };
  protonGeBin10 = pkgs.callPackage ./pkgs/proton-ge-bin-10.nix { };
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot = {
    tmp.cleanOnBoot = true;

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 0;
    };

    plymouth = {
      enable = true;
    };

    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "intel_idle.max_cstate=1"
      "processor.max_cstate=1"
      "split_lock_detect=off"
      # "amdgpu.freesync_video=1" # Enable FreeSync for video playback
      # "amdgpu.dc=1" # Explicitly enable Display Core (required for DSC)
      # "amdgpu.dc_log=1"  # Uncomment to enable verbose DC debug logging

      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
      # Keep the firmware/Plymouth framebuffer alive through the handoff to the
      # display manager where the AMD driver supports it.
      "amdgpu.seamless=1"
      "intel_iommu=on"

      # disable NVME power saving
      # "nvme_core.default_ps_max_latency_us=0"
    ];

    kernel.sysctl = {
      "vm.max_map_count" = 2147483642; # Required for many modern games
      "vm.swappiness" = 20; # Prefer RAM/file cache for gaming; still use zram under pressure
      "fs.file-max" = 524288; # Increase file descriptor limit
    };
    kernel.sysfs = {
      devices.system.cpu.intel_pstate.hwp_dynamic_boost = 1;
    };
  };

  hardware.cpu.intel.updateMicrocode = true;

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "builder.cbannister.casa";
        system = "x86_64-linux";
        sshUser = "nix-remote-builder";
        sshKey = "/var/lib/nix-remote-builder/id_ed25519";
        publicHostKey = "AAAAC3NzaC1lZDI1NTE5AAAAIGHcCpiRC/tkGOIxAM4bSjiasAIFzxTj9iDxhsxo/kNK";
        protocol = "ssh";
        maxJobs = 8; # EPYC remote builder VM capacity
        speedFactor = 8; # Strongly prefer remote builder over local builds
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
      }
    ];

    settings = {
      # Keep derivation concurrency moderate, but let large local builds such as
      # the kernel use the CPU instead of compiling with only a few jobs.
      max-jobs = 4;
      cores = 0;
      builders-use-substitutes = true;
      extra-sandbox-paths = [ config.programs.ccache.cacheDir ];
    };
  };

  # programs.ccache = {
  #   enable = true;
  #   packageNames = [ "linux_latest" ];
  #   trace = false;
  # };

  # Use latest kernel via the top-level package so programs.ccache can wrap it.
  # boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_latest;

  # TP-Link UB600 / Realtek 8761BUV advertises as 37ad:0600, but kernels before
  # the upstream quirk bind it as generic btusb and skip Realtek firmware setup.
  # Upstream patch: https://www.spinics.net/lists/linux-bluetooth/msg129364.html
  # boot.kernelPatches = [
  #   {
  #     name = "tp-link-ub600-realtek-8761buv";
  #     patch = ./patches/tp-link-ub600-realtek-8761buv.patch;
  #   }
  # ];

  sops.secrets.nix-remote-builder-key = {
    sopsFile = ../../secrets/nix-remote-builder.yaml;
    key = "nix_remote_builder_private_key";
    path = "/var/lib/nix-remote-builder/id_ed25519";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  networking.hostName = "gaming"; # Define your hostname.

  networking.firewall.enable = false;
  networking.nameservers = [ "172.53.53.53" ];
  networking.search = [ "cbannister.casa" ];

  # Enable networking
  networking.networkmanager.enable = false;
  networking.useDHCP = false;
  services.resolved.enable = true;
  services.timesyncd = {
    enable = true;
    servers = [ "10.254.254.1" ];
  };
  systemd.network = {
    enable = true;
    links = {
      "10-enp6s0" = {
        matchConfig.OriginalName = "enp6s0";
        linkConfig.WakeOnLan = "off";
      };
      "10-enp7s0f0np0" = {
        matchConfig.OriginalName = "enp7s0f0np0";
        linkConfig.WakeOnLan = "off";
      };
      "10-enp7s0f1np1" = {
        matchConfig.OriginalName = "enp7s0f1np1";
        linkConfig.WakeOnLan = "off";
      };
    };
    netdevs."10-bond0" = {
      netdevConfig = {
        Name = "bond0";
        Kind = "bond";
      };
      bondConfig = {
        Mode = "active-backup";
        PrimaryReselectPolicy = "always";
        MIIMonitorSec = "1s";
      };
    };
    networks."10-bond0" = {
      matchConfig.Name = "bond0";
      networkConfig.DHCP = "no";
      address = [ "10.1.2.16/24" ];
      gateway = [ "10.1.2.1" ];
      dns = [ "172.53.53.53" ];
      domains = [ "cbannister.casa" ];
    };
    networks."10-enp7s0f0np0" = {
      matchConfig.Name = "enp7s0f0np0";
      networkConfig = {
        Bond = "bond0";
        DHCP = "no";
        PrimarySlave = true;
      };
    };
    networks."10-enp6s0" = {
      matchConfig.Name = "enp6s0";
      networkConfig = {
        Bond = "bond0";
        DHCP = "no";
      };
    };
  };

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

  services.fstrim.enable = true;

  # Hibernate needs persistent swap; zram is useful for runtime pressure but
  # cannot store a suspend-to-disk image after power-off.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 64 * 1024;
      priority = 10;
      discardPolicy = "both";
    }
  ];
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 60;
    priority = 100;
  };

  # Enable the KDE Plasma Desktop Environment.
  # Default normal interactive logins to Niri managed by UWSM.
  services.displayManager.defaultSession = "niri-uwsm";
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true; # Enable Wayland for better VRR support
  };
  services.desktopManager.plasma6.enable = true;
  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "mauve";
    plymouth.enable = true;
    sddm = {
      enable = true;
      font = "JetBrainsMono Nerd Font";
    };
    tty.enable = true;
  };
  programs.niri.enable = true;
  programs.uwsm = {
    enable = true;
    waylandCompositors.niri = {
      prettyName = "Niri";
      comment = "Niri compositor managed by UWSM";
      binPath = "${pkgs.niri}/bin/niri-session";
    };
  };
  programs.xwayland.enable = true;

  environment.etc."xdg/menus/niri-session-applications.menu".source =
    "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = lib.mkForce "us";
    variant = "";
    model = "pc105";
  };

  # Configure console keymap
  console.keyMap = lib.mkForce "us";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  security.pam.services.hyprlock = { };
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
  users.groups = {
    apps.gid = 568;
    shared.gid = 3005;
    steam = { };
  };
  users.users.chris = {
    isNormalUser = true;
    description = "chris";
    extraGroups = [
      "networkmanager"
      "wheel"
      "gamemode"
      "shared"
      "apps"
      "steam"
      "video"
      "render"
      "kvm"
      "libvirtd"
      "dialout"
    ];
    shell = pkgs.fish;
    packages = with pkgs; [
      kdePackages.kate
      kdePackages.kalk
      #  thunderbird
    ];
  };

  systemd.tmpfiles.rules = lib.mkAfter [
    "q /tmp 1777 root root 2d"
    "d /var/lib/nix-remote-builder 0700 root root -"
    "d /srv/steam-library 2775 root steam -"
    "d /srv/steam-library/steamapps 2775 root steam -"
    "a+ /srv/steam-library - - - - group:steam:rwx,default:group:steam:rwx,mask::rwx,default:mask::rwx"
    "a+ /srv/steam-library/steamapps - - - - group:steam:rwx,default:group:steam:rwx,mask::rwx,default:mask::rwx"
  ];

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
    package = pkgs.steam.override {
      # extraArgs = "-silent -pipewire";
      extraArgs = "-silent";
      extraEnv = {
        DRI_PRIME = "pci-0000_03_00_0";
        # LIBVA_DRIVER_NAME = "radeonsi";
        VKD3D_CONFIG = "descriptor_heap";
        PROTON_ENABLE_WAYLAND = 1;
      };
    };
    protontricks.enable = true;
    extraPackages = [ gamemodeSteamCompat ];
    extraCompatPackages = with pkgs; [
      proton-ge-bin
      protonGeBin10
    ];
  };

  programs.gamemode = {
    enable = true;
    package = gamemodeSteamCompat;
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

  xdg.portal = {
    enable = true;
    config = {
      kde.default = [
        "kde"
      ];
      plasma.default = [
        "kde"
      ];
    };
  };

  hardware.graphics = {
    enable = lib.mkDefault true;
    enable32Bit = lib.mkDefault true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
      vpl-gpu-rt
    ];
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
    libva-utils
    mpv
    xdg-utils
    shared-mime-info
    nvme-cli
    smartmontools
    config.boot.kernelPackages.turbostat
    caligula
    mstflint
    # inputs.nixpkgs-gamma.legacyPackages.${pkgs.system}.gamma-launcher
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    via
    vial
    qmk
    qmk-udev-rules
    xwayland-satellite
    wlogout
    (catppuccin-kde.override {
      flavour = [ "mocha" ];
      accents = [ "mauve" ];
      winDecStyles = [ "modern" ];
    })
    # flint
    bluez

    qemu_kvm
    go
    libvirt
    virt-manager
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
      runAsRoot = true;
    };
  };
  programs.virt-manager.enable = true;

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  services.udev.packages = with pkgs; [
    via
    vial
    qmk-udev-rules
  ];
  services.udev.extraRules = ''
    # Keep the power button as the primary wake source. The current logs show
    # S3/S4 wakes with broad PCIe/USB/RTC wake sources enabled.
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:00:01.0", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:01:00.0", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:00:14.0", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:00:1a.0", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:00:1c.0", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:00:1c.2", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:00:1c.4", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="platform", KERNEL=="rtc_cmos", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="platform", KERNEL=="ACPI000E:00", ATTR{power/wakeup}="disabled"
  '';

  # Keep broadly safe Vulkan defaults global. Proton renderer and upscaler
  # experiments are safer as per-title Steam launch options.
  environment.sessionVariables = {
    RADV_PERFTEST = "gpl,nggc"; # Enable GPL shader compilation and NGG culling
    AMD_VULKAN_ICD = "RADV"; # Use RADV driver
    PROTON_USE_NTSYNC = "1";
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

  fonts.packages = with pkgs; [
    font-awesome
    nerd-fonts.jetbrains-mono
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
