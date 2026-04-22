# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  pkgs,
  lib,
  ...
}:

let
  moonlightCommand = pkgs.writeShellScript "moonlight" ''
    export NIXOS_OZONE_WL=1
    export SDL_VIDEODRIVER=wayland
    exec ${pkgs.moonlight-qt}/bin/moonlight
  '';

  swayConfig = pkgs.writeText "sway-moonlight.conf" ''
    output * bg #000000 solid_color

    default_border pixel 0
    default_floating_border pixel 0
    focus_follows_mouse no

    input type:keyboard {
      xkb_layout gb
    }

    bindsym XF86PowerOff exec ${pkgs.systemd}/bin/systemctl suspend
    bindsym Ctrl+Alt+BackSpace exec ${pkgs.systemd}/bin/loginctl terminate-user gaming

    # Let UWSM mark the graphical session ready and export SWAYSOCK/WAYLAND_DISPLAY.
    exec ${pkgs.uwsm}/bin/uwsm finalize SWAYSOCK

    for_window [app_id="moonlight"] fullscreen enable
    for_window [class="moonlight"] fullscreen enable
  '';
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 0;
    };

    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "quiet"
      "splash"
      "usbcore.autosuspend=-1"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
    plymouth = {
      enable = true;
      theme = "rings";
      themePackages = with pkgs; [
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "rings" ];
        })
      ];
    };
  };

  boot.kernel.sysctl = {
    "fs.file-max" = 524288;
    "vm.max_map_count" = 2147483642;
  };

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
  networking.hostName = "thinliz";
  networking.useDHCP = false;
  services.resolved.enable = true;
  systemd.network = {
    enable = true;
    networks."10-wired" = {
      matchConfig.Driver = "igc";
      networkConfig.DHCP = "no";
      address = [ "10.1.2.102/24" ];
      gateway = [ "10.1.2.1" ];
      dns = [ "172.53.53.53" ];
      domains = [ "cbannister.casa" ];
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

  programs.uwsm = {
    enable = true;
    waylandCompositors.sway = {
      prettyName = "Sway";
      comment = "Sway compositor managed by UWSM";
      binPath = "/run/current-system/sw/bin/sway";
      extraArgs = [
        "--config"
        "${swayConfig}"
      ];
    };
  };

  programs.sway = {
    enable = true;
    wrapperFeatures = {
      base = false;
      gtk = true;
    };
  };
  programs.xwayland.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${pkgs.uwsm}/bin/uwsm start -eD sway -N Sway -C 'Sway compositor managed by UWSM' -F -- /run/current-system/sw/bin/sway --config ${swayConfig}";
        user = "gaming";
      };
      default_session = {
        command = "${pkgs.greetd}/bin/agreety --cmd /run/current-system/sw/bin/login";
        user = "greeter";
      };
    };
  };

  services.dbus.implementation = lib.mkForce "dbus";

  hardware = {
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-compute-runtime
        intel-media-driver
      ];
    };
    xone.enable = true;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  systemd.user.services.moonlight = {
    description = "Moonlight streaming client";
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    startLimitIntervalSec = 30;
    startLimitBurst = 20;
    serviceConfig = {
      ExecStart = "${moonlightCommand}";
      Restart = "always";
      RestartSec = 2;
      Slice = "app-graphical.slice";
    };
  };

  services.fstrim.enable = true;
  services.fwupd.enable = true;

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
  users.users.gaming = {
    isNormalUser = true;
    description = "gaming";
    extraGroups = [ "video" ];
    shell = pkgs.bashInteractive;
  };

  programs.fish.enable = true;

  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    linux-firmware
    moonlight-qt
    vulkan-tools
    pciutils
    usbutils
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
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

  system.stateVersion = "25.11"; # Did you read the comment?
}
