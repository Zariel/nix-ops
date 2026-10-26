{ config, ... }:
{
  # The base role uses /etc/ssh/ssh_host_ed25519_key as the age identity.
  sops.useSystemdActivation = true;
  sops.secrets.gateway-wireguard = {
    sopsFile = ../../secrets/gateway.yaml;
    key = "wireguard_private_key";
    owner = "root";
    group = "systemd-network";
    mode = "0440";
    reloadUnits = [ "systemd-networkd.service" ];
  };

  systemd.network.netdevs."20-wg01".wireguardConfig.PrivateKeyFile =
    config.sops.secrets.gateway-wireguard.path;

  # networkd starts early; do not let it read the netdev before its key exists.
  systemd.services.systemd-networkd = {
    requires = [ "sops-install-secrets.service" ];
    after = [ "sops-install-secrets.service" ];
  };
}
