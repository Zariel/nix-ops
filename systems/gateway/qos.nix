{ pkgs, ... }:
let
  apply = pkgs.writeShellScript "gateway-cake" ''
    set -eu
    tc=${pkgs.iproute2}/bin/tc
    # replace is idempotent and updates shaping without cycling the WAN link.
    $tc qdisc replace dev wan0 root cake bandwidth 950mbit dual-srchost nat rtt 20ms
    $tc qdisc replace dev ifb0 root cake bandwidth 890mbit dual-dsthost nat ingress rtt 20ms
    $tc qdisc replace dev wan0 handle ffff: ingress
    $tc filter replace dev wan0 parent ffff: protocol all pref 10 matchall action mirred egress redirect dev ifb0
  '';
in
{
  systemd.services.gateway-cake = {
    description = "WAN CAKE upload and download shaping";
    wantedBy = [ "multi-user.target" ];
    requires = [
      "sys-subsystem-net-devices-wan0.device"
      "sys-subsystem-net-devices-ifb0.device"
    ];
    after = [
      "sys-subsystem-net-devices-wan0.device"
      "sys-subsystem-net-devices-ifb0.device"
    ];
    reloadIfChanged = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = apply;
      ExecReload = apply;
    };
  };
}
