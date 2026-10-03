{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.dnsVip;
  kubernetesDomains = generators.toLua { multiline = false; } cfg.kubernetesDomains;
  kubernetesHealthCheckDomain = builtins.toJSON "${builtins.head cfg.kubernetesDomains}.";
  dnsdistConfig =
    builtins.replaceStrings
      [
        "@KUBERNETES_DOMAINS@"
        "@KUBERNETES_HEALTH_CHECK_DOMAIN@"
      ]
      [
        kubernetesDomains
        kubernetesHealthCheckDomain
      ]
      (builtins.readFile ./files/dnsdist/config.lua);
  dnsdistConfigPath = pkgs.writeText "dnsdist.conf" dnsdistConfig;
  dnsdistConfigCheck = pkgs.writeShellScript "dnsdist-configcheck" ''
    set -euo pipefail
    ${pkgs.lua}/bin/luac -p ${dnsdistConfigPath}
  '';
in
{
  config = mkIf cfg.enable {
    services.dnsdist = {
      listenAddress = "172.53.53.53";
      listenPort = 53;
      extraConfig = dnsdistConfig;
    };

    # Ensure dnsdist starts after the dnsvip interface is ready and after bind/blocky are running
    systemd.services.dnsdist = {
      after = [
        "sys-subsystem-net-devices-dnsvip.device"
        "bind.service"
        "blocky.service"
      ];
      bindsTo = [ "sys-subsystem-net-devices-dnsvip.device" ];
      requires = [
        "bind.service"
        "blocky.service"
      ];
      wants = [
        "bind.service"
        "blocky.service"
      ];
      startLimitIntervalSec = mkForce 60;
      startLimitBurst = mkForce 5;
      serviceConfig = {
        ExecStartPre = dnsdistConfigCheck;
        Restart = "on-failure";
        RestartSec = "5s";
        TimeoutStartSec = "30s";
      };
    };
  };
}
