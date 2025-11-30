{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.anomalyMods;
  homeDir = config.home.homeDirectory;
  sanitize = str: lib.replaceStrings [ " " "/" ":" "." ] [ "-" "-" "-" "-" ] str;

  mkService =
    version: mod:
    let
      modRoot = "${cfg.baseDir}/anomaly-${version}/${mod.name}";
      lowerDir = "${cfg.baseDir}/anomaly-${version}/anomaly";
      upperDir = "${modRoot}/.upper";
      workDir = "${modRoot}/.work";
      mountPoint = "${modRoot}/anomaly";
      serviceName = "anomaly-${sanitize version}-${sanitize mod.name}";
    in
    {
      name = serviceName;
      value = {
        Unit = {
          Description = "OverlayFS for S.T.A.L.K.E.R. Anomaly ${version} (${mod.name})";
          After = [ "default.target" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "anomaly-overlay-${serviceName}-start" ''
            set -euo pipefail

            lower="${lowerDir}"
            upper="${upperDir}"
            work="${workDir}"
            merged="${mountPoint}"

            mkdir -p "$upper" "$work" "$merged"

            if [ ! -d "$lower" ]; then
              echo "Missing base Anomaly directory: $lower" >&2
              exit 1
            fi

            if ${pkgs.util-linux}/bin/mountpoint -q "$merged"; then
              echo "Anomaly overlay already mounted at $merged"
              exit 0
            fi

            ${pkgs.util-linux}/bin/mount -t overlay overlay \
              -o lowerdir="$lower",upperdir="$upper",workdir="$work" \
              "$merged"
          '';
          ExecStop = pkgs.writeShellScript "anomaly-overlay-${serviceName}-stop" ''
            set -euo pipefail

            merged="${mountPoint}"

            if ${pkgs.util-linux}/bin/mountpoint -q "$merged"; then
              ${pkgs.util-linux}/bin/umount "$merged"
            fi
          '';
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
in
{
  options.programs.anomalyMods = {
    enable = lib.mkEnableOption "Overlay-backed S.T.A.L.K.E.R. Anomaly mod instances";

    baseDir = lib.mkOption {
      type = lib.types.str;
      default = "${homeDir}/games/anomaly";
      example = "${homeDir}/Games/anomaly";
      description = ''
        Base directory under the user's home that holds Anomaly installs and per-mod overlays.
        The module only mounts overlay views; game assets stay outside the Nix store.
      '';
    };

    versions = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.listOf (
          lib.types.submodule (
            { name, ... }:
            {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Directory name for this mod under the versioned Anomaly tree.";
                };
              };
            }
          )
        )
      );
      default = { };
      description = "Mod instances keyed by Anomaly version.";
      example = {
        "v1.5.3" = [
          { name = "gamma"; }
          { name = "EFP"; }
        ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services = lib.mkMerge (
      lib.mapAttrsToList (
        version: mods: lib.listToAttrs (map (mod: mkService version mod) mods)
      ) cfg.versions
    );
  };
}
