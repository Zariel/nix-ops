# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  pkgs,
  lib,
  ...
}:

let
  moonlightOutputHeight = "2160";
  moonlightOutputMode = "${moonlightOutputWidth}x${moonlightOutputHeight}@${moonlightOutputRefresh}Hz";
  moonlightOutputName = "HDMI-A-1";
  moonlightOutputRefresh = "60";
  moonlightOutputWidth = "3840";

  moonlightDiagnostics = pkgs.writeShellScriptBin "lounge-moonlight-diagnostics" ''
    set +e

    log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/moonlight"
    mkdir -p "$log_dir"
    stamp="''${XDG_RUNTIME_DIR:-/tmp}/lounge-moonlight-diagnostics-last-run"
    now="$(${pkgs.coreutils}/bin/date +%s)"

    if [ "''${1:-}" != "--force" ]; then
      last="$(${pkgs.coreutils}/bin/cat "$stamp" 2>/dev/null || echo 0)"
      if [ "$((now - last))" -lt 300 ]; then
        exit 0
      fi
    fi

    printf '%s\n' "$now" >"$stamp"
    log="$log_dir/diagnostics-$(${pkgs.coreutils}/bin/date +%Y%m%d-%H%M%S).log"

    {
      echo "== session =="
      ${pkgs.coreutils}/bin/date --iso-8601=seconds
      id
      echo "XDG_SESSION_ID=''${XDG_SESSION_ID:-}"
      echo "XDG_SESSION_TYPE=''${XDG_SESSION_TYPE:-}"
      echo "XDG_CONFIG_DIRS=''${XDG_CONFIG_DIRS:-}"
      echo "XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-}"
      echo "WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-}"
      echo "QT_QPA_PLATFORM=''${QT_QPA_PLATFORM:-}"
      echo "LIBVA_DRIVER_NAME=''${LIBVA_DRIVER_NAME:-}"
      echo "PREFER_VULKAN=''${PREFER_VULKAN:-}"
      echo

      echo "== loginctl session =="
      if [ -n "''${XDG_SESSION_ID:-}" ]; then
        ${pkgs.systemd}/bin/loginctl show-session "$XDG_SESSION_ID" \
          -p Type -p Class -p Active -p State -p Remote -p Seat
      fi
      echo

      echo "== drm devices =="
      ${pkgs.coreutils}/bin/ls -l /dev/dri || true
      ${pkgs.drm_info}/bin/drm_info || true
      echo

      echo "== wayland outputs =="
      ${pkgs.wlr-randr}/bin/wlr-randr || true
      ${pkgs.wayland-utils}/bin/wayland-info || true
      echo

      echo "== vaapi drm =="
      ${pkgs.libva-utils}/bin/vainfo --display drm --device /dev/dri/renderD128 || true
      echo

      echo "== vaapi wayland =="
      ${pkgs.libva-utils}/bin/vainfo --display wayland || true
      echo

      echo "== vulkan =="
      ${pkgs.vulkan-tools}/bin/vulkaninfo --summary || true
      echo

      echo "== audio =="
      ${pkgs.pulseaudio}/bin/pactl info || true
      ${pkgs.pulseaudio}/bin/pactl list short sinks || true
      echo

      echo "== input =="
      ${pkgs.coreutils}/bin/ls -l /dev/input/by-id /dev/input/by-path || true
    } >"$log" 2>&1

    ${pkgs.coreutils}/bin/ln -sfn "$log" "$log_dir/diagnostics-latest.log"
  '';

  moonlightWaylandApp = pkgs.writeShellScript "moonlight-wayland-app" ''
    set -eu

    log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/moonlight"
    mkdir -p "$log_dir"

    export LIBVA_DRIVER_NAME=iHD
    export PREFER_VULKAN=1
    export QT_QPA_PLATFORM=wayland
    export SDL_VIDEODRIVER=wayland
    export XDG_CONFIG_DIRS="/etc/xdg''${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}"
    export XDG_CURRENT_DESKTOP=sway
    export XDG_SESSION_TYPE=wayland

    ${moonlightDiagnostics}/bin/lounge-moonlight-diagnostics || true

    exec ${pkgs.moonlight-qt}/bin/moonlight >>"$log_dir/session.log" 2>&1
  '';

  moonlightAppLoop = pkgs.writeShellScript "moonlight-app-loop" ''
    set -eu

    while true; do
      ${moonlightWaylandApp} || true
      sleep 2
    done
  '';

  moonlightSwayConfig = pkgs.writeText "moonlight-sway.conf" ''
    set $mod Mod4

    output ${moonlightOutputName} mode ${moonlightOutputMode} pos 0 0 scale 1

    default_border none
    default_floating_border none
    hide_edge_borders smart
    gaps inner 0
    seat * hide_cursor 3000

    bindsym $mod+Shift+e exec ${pkgs.sway}/bin/swaymsg exit

    for_window [app_id="moonlight"] fullscreen enable
    for_window [app_id="Moonlight"] fullscreen enable
    for_window [title="Moonlight"] fullscreen enable

    exec ${moonlightAppLoop}
  '';

  moonlightSessionCommand = pkgs.writeShellScript "moonlight-session" ''
    set -eu

    log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/moonlight"
    mkdir -p "$log_dir"

    while true; do
      ${pkgs.dbus}/bin/dbus-run-session \
        ${pkgs.sway}/bin/sway -d -c ${moonlightSwayConfig} >>"$log_dir/sway.log" 2>&1 || true
      sleep 2
    done
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
      "i915.force_probe=!a7a0"
      "usbcore.autosuspend=-1"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
      "xe.force_probe=a7a0"
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
  networking.firewall.enable = false;
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

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${moonlightSessionCommand}";
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
    };
    intelgpu = {
      driver = "xe";
      vaapiDriver = "intel-media-driver";
    };
    xone.enable = true;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
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
    extraGroups = [
      "render"
      "video"
    ];
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
    wireplumber.extraConfig."90-hdmi-avr" = {
      "wireplumber.settings" = {
        "device.restore-profile" = false;
        "device.restore-routes" = false;
        "linking.pause-playback" = false;
        "monitor.alsa.autodetect-hdmi-channels" = true;
        "node.restore-default-targets" = false;
      };
      "device.profile.priority.rules" = [
        {
          matches = [
            {
              "device.name" = "~alsa_card.*";
            }
          ];
          actions = {
            update-props = {
              priorities = [
                "output:hdmi-surround"
                "output:hdmi-surround71"
                "output:hdmi-stereo"
                "off"
              ];
            };
          };
        }
      ];
      "monitor.alsa.rules" = [
        {
          matches = [
            {
              "device.profile.name" = "~hdmi.*";
              "media.class" = "Audio/Sink";
            }
          ];
          actions = {
            update-props = {
              "priority.session" = 20000;
              "session.suspend-timeout-seconds" = 0;
            };
          };
        }
      ];
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.etc."xdg/Moonlight Game Streaming Project/Moonlight.conf".text = ''
    [General]
    videodec=2
  '';

  environment.systemPackages = with pkgs; [
    drm_info
    libva-utils
    linux-firmware
    mesa-demos
    moonlight-qt
    moonlightDiagnostics
    pciutils
    sway
    tcpdump
    usbutils
    vulkan-tools
    wayland-utils
    wlr-randr
  ];

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
