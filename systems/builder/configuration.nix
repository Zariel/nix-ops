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
      dns = [ "172.53.53.53" ];
    };
  };

  # Builder-specific nix settings
  nix.settings = {
    # Build parallelism - 8 cores, 32GB RAM
    max-jobs = 8; # Run up to 8 builds in parallel
    cores = 4; # Each build can use 4 cores (8 * 4 = 32 max, but typically less)

    # Garbage collection thresholds
    min-free = lib.mkDefault (2 * 1024 * 1024 * 1024); # 2GB
    max-free = lib.mkDefault (20 * 1024 * 1024 * 1024); # 20GB
  };

  # Number of build users for parallel builds
  nix.nrBuildUsers = 32;

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

  # Cache warming service - periodically builds all system configurations
  # This ensures Harmonia's cache stays warm for offline deployments
  systemd.services.cache-warmer = {
    description = "Build all NixOS configurations to warm Harmonia cache";
    path = with pkgs; [
      nix
      git
      jq
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "chris";
      TimeoutSec = "4h"; # Allow time for first run downloads/builds
    };
    script = ''
      set -e

      REPO_DIR="/home/chris/nix-ops"

      # Clone or update repository
      if [ ! -d "$REPO_DIR" ]; then
        echo "Cloning nix-ops repository..."
        git clone https://github.com/Zariel/nix-ops.git "$REPO_DIR" || {
          echo "Failed to clone repository, skipping this run"
          exit 0
        }
      else
        echo "Updating nix-ops repository..."
        cd "$REPO_DIR"
        git pull || {
          echo "Failed to pull updates, using existing version"
        }
      fi

      cd "$REPO_DIR"

      # Build all system configurations
      # Builds are stored in /nix/store and served by Harmonia
      echo "Discovering nixosConfigurations from flake..."
      SYSTEMS=$(nix eval "$REPO_DIR#nixosConfigurations" --apply builtins.attrNames --json | jq -r '.[]')

      if [ -z "$SYSTEMS" ]; then
        echo "Error: No systems found in flake"
        exit 1
      fi

      echo "Found systems: $(echo $SYSTEMS | tr '\n' ' ')"
      echo "Building system configurations..."

      for system in $SYSTEMS; do
        echo "Building $system..."
        nix build ".#nixosConfigurations.$system.config.system.build.toplevel" \
          --print-build-logs \
          --keep-going || {
          echo "Warning: Failed to build $system, continuing..."
        }
      done

      echo "Cache warming complete - all builds available via Harmonia at http://10.1.1.155:5000"
    '';
  };

  systemd.timers.cache-warmer = {
    enable = false;
    description = "Timer for periodic cache warming builds";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # Run hourly
      OnCalendar = "hourly";
      # Run on boot if missed during downtime
      Persistent = true;
      # Randomize start time within 5 minutes to avoid thundering herd
      RandomizedDelaySec = "5m";
    };
  };
}
