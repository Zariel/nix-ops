{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.dnsVip;
  dnsdistConfigPath = ./files/dnsdist/config.lua;
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
      extraConfig = (builtins.readFile dnsdistConfigPath);
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
      serviceConfig = {
        ExecStartPre = dnsdistConfigCheck;
        Restart = "on-failure";
        RestartSec = "5s";
        StartLimitIntervalSec = 60;
        StartLimitBurst = 5;
        TimeoutStartSec = "30s";
      };
    };
  };
}
