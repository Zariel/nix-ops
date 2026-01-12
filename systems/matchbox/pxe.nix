{ lib, pkgs, ... }:
let
  myIpxe = pkgs.ipxe.override {
    embedScript = pkgs.writeText "embed.ipxe" ''
      #!ipxe
      dhcp
      chain http://10.1.1.20:8080/boot.ipxe
    '';
  };
in
{
  environment.systemPackages = lib.mkAfter (
    with pkgs;
    [
      myIpxe
      matchbox-server
    ]
  );

  services.atftpd = {
    enable = true;
    root = "/etc/tftpboot";
  };

  environment.etc."tftpboot/ipxe.efi".source = "${myIpxe}/ipxe.efi";

  users.groups.matchbox = {
    members = [
      "matchbox"
      "chris"
    ];
  };

  users.users.matchbox = {
    isSystemUser = true;
    group = "matchbox";
  };

  systemd.services.matchbox = {
    description = "Matchbox bare-metal provisioning service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.matchbox-server}/bin/matchbox \
        -address=0.0.0.0:8080 \
        -rpc-address=0.0.0.0:8081 \
        -data-path=/var/lib/matchbox";
      User = "matchbox";
      Group = "matchbox";
      StateDirectory = "matchbox"; # => /var/lib/matchbox
    };
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/matchbox/groups   2755 matchbox matchbox -"
    "d /var/lib/matchbox/profiles 2755 matchbox matchbox -"
    "d /var/lib/matchbox/assets   2755 matchbox matchbox -"
  ];
}
