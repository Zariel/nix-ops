{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.dnsHealthcheck;

  healthCheckScript = pkgs.writeShellScript "dns-health-check" ''
    set -euo pipefail

    CHECK_INTERVAL=${toString cfg.checkInterval}
    FAILURE_THRESHOLD=${toString cfg.failureThreshold}
    SUCCESS_THRESHOLD=${toString cfg.successThreshold}
    DNS_TIMEOUT=${toString cfg.dnsTimeout}
    HEALTH_CHECK_PORT=${toString cfg.healthCheckPort}
    BIRD_PROTOCOL="${cfg.birdProtocolName}"

    failure_count=0
    success_count=0
    advertising=false

    log() {
      echo "$(date '+%Y-%m-%d %H:%M:%S') - $*"
    }

    check_dns_health() {
      # Query dnsdist on localhost health check listener
      # This works regardless of OSPF advertisement state
      if timeout "$DNS_TIMEOUT" ${pkgs.dnsutils}/bin/dig @127.0.0.1 -p "$HEALTH_CHECK_PORT" google.com +short +tries=1 > /dev/null 2>&1; then
        return 0
      else
        return 1
      fi
    }

    is_bird_advertising() {
      # Check if BIRD direct protocol is enabled
      ${pkgs.bird2}/bin/birdc show protocols "$BIRD_PROTOCOL" | grep -q "up"
    }

    enable_bird_advertisement() {
      if ! is_bird_advertising; then
        log "HEALTH OK - Enabling BIRD OSPF advertisement after $success_count consecutive successes"
        ${pkgs.bird2}/bin/birdc enable "$BIRD_PROTOCOL" > /dev/null 2>&1 || log "WARNING: Failed to enable BIRD protocol"
        advertising=true
        failure_count=0
        success_count=0
      fi
    }

    disable_bird_advertisement() {
      if is_bird_advertising; then
        log "HEALTH FAILED - Disabling BIRD OSPF advertisement after $failure_count consecutive failures"
        ${pkgs.bird2}/bin/birdc disable "$BIRD_PROTOCOL" > /dev/null 2>&1 || log "WARNING: Failed to disable BIRD protocol"
        advertising=false
        failure_count=0
        success_count=0
      fi
    }

    # Initialize state - start with advertisement disabled for clean startup
    if is_bird_advertising; then
      log "Starting with BIRD advertising enabled - disabling for clean startup"
      ${pkgs.bird2}/bin/birdc disable "$BIRD_PROTOCOL" > /dev/null 2>&1 || true
      advertising=false
    else
      log "Starting with BIRD advertising disabled"
      advertising=false
    fi

    log "DNS health monitoring started (check every ''${CHECK_INTERVAL}s, fail threshold: $FAILURE_THRESHOLD, success threshold: $SUCCESS_THRESHOLD)"

    while true; do
      if check_dns_health; then
        failure_count=0

        if [ "$advertising" = false ]; then
          success_count=$((success_count + 1))
          log "Health check passed ($success_count/$SUCCESS_THRESHOLD) - Not yet advertising"

          if [ $success_count -ge $SUCCESS_THRESHOLD ]; then
            enable_bird_advertisement
          fi
        else
          success_count=0
        fi

      else
        success_count=0

        if [ "$advertising" = true ]; then
          failure_count=$((failure_count + 1))
          log "Health check FAILED ($failure_count/$FAILURE_THRESHOLD) - Still advertising"

          if [ $failure_count -ge $FAILURE_THRESHOLD ]; then
            disable_bird_advertisement
          fi
        else
          failure_count=0
        fi
      fi

      sleep $CHECK_INTERVAL
    done
  '';

in
{
  options.services.dnsHealthcheck = {
    enable = mkEnableOption "DNS health check with BIRD OSPF advertisement control";

    nodeIp = mkOption {
      type = types.str;
      description = "Node IP address (used for BIRD router-id)";
      example = "10.1.53.10";
    };

    healthCheckPort = mkOption {
      type = types.int;
      default = 5380;
      description = "Port for dnsdist health check listener on localhost";
    };

    birdProtocolName = mkOption {
      type = types.str;
      default = "dnsvip_direct";
      description = "Name of BIRD direct protocol to control for advertisement";
    };

    checkInterval = mkOption {
      type = types.int;
      default = 5;
      description = "Seconds between health checks";
    };

    failureThreshold = mkOption {
      type = types.int;
      default = 3;
      description = "Consecutive failures before disabling OSPF advertisement";
    };

    successThreshold = mkOption {
      type = types.int;
      default = 2;
      description = "Consecutive successes before enabling OSPF advertisement";
    };

    dnsTimeout = mkOption {
      type = types.int;
      default = 2;
      description = "DNS query timeout in seconds";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.dns-healthcheck = {
      description = "DNS Service Health Monitor with BIRD OSPF Advertisement Control";

      after = [
        "network-online.target"
        "systemd-networkd.service"
        "bird.service"
        "dnsdist.service"
      ];
      wants = [ "bird.service" "dnsdist.service" ];
      requires = [ "systemd-networkd.service" "bird.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "10s";
        User = "root";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;

        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "dns-healthcheck";

        MemoryLimit = "50M";
        TasksMax = 10;
      };

      script = toString healthCheckScript;
    };
  };
}
