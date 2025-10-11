{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.dnsVip;
in
{
  config = mkIf cfg.enable {
    services.dnsdist = {
      listenAddress = "172.53.53.53";
      listenPort = 53;
      extraConfig = (builtins.readFile ./files/dnsdist/config.lua);
    };
  };
}
