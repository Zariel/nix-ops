{
  pkgs,
  codex-cli-nix,
  llm-agents,
  config,
  lib,
  osConfig,
  ...
}:
let
  home = config.home.homeDirectory;

  llmAgentPackages = llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  beadsPackage = llmAgentPackages.beads;

  formatCommitMessage = pkgs.callPackage ../pkgs/format-commit-message.nix { };

  bd = pkgs.writeShellApplication {
    name = "bd";

    runtimeInputs = [
      pkgs.systemd
    ];

    text = ''
      exec systemd-run \
        --user \
        --scope \
        --quiet \
        --collect \
        --property=MemoryHigh=2G \
        --property=MemoryMax=4G \
        --property=MemorySwapMax=1G \
        ${pkgs.lib.getExe' beadsPackage "bd"} "$@"
    '';
  };
in
{
  imports = [
    ./appearance.nix
    ./default-apps.nix
    ./desktop-shell.nix
    ./gaming.nix
    ./kde.nix
    ./niri-session.nix
  ];

  home.packages = with pkgs; [
    p7zip
    unzip
    wget
    unrar
    deploy-rs
    obsidian
    mpv
    bubblewrap
    rustup
    kubectl
    mkbrr
    bd
    formatCommitMessage
    gcc
    glow
  ];

  home.shellAliases = {
    k = "kubectl";
  };

  # Home Manager's default sd-switch restarts changed user units during
  # activation. In a UWSM session, those units are tied to graphical-session.target,
  # so restarting them can complete UWSM's bind-PID unit and end the compositor.
  systemd.user.startServices = "suggest";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings."*" = {
      IdentityAgent = "${home}/.1password/agent.sock";
    };
  };

  programs.codex = {
    enable = true;
    package = codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    skills = {
      draft-commit = ./apps/codex/skills/draft-commit.md;
      technical-doc-writer = ./apps/codex/skills/technical-doc-writer;
    };
    context = builtins.readFile ./apps/codex/context.md;
  };

  systemd.user.services.codex-app-server = {
    Unit = {
      Description = "Codex background server";
      X-Restart-Triggers = [ osConfig.environment.etc."codex/config.toml".source ];
    };

    Service = {
      ExecStart = "${pkgs.lib.getExe config.programs.codex.package} app-server --listen unix://";
      WorkingDirectory = home;
      Environment = [ "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin" ];
      Restart = "on-failure";
      RestartSec = 2;
      # Let the server shut down its workers before systemd kills remaining children.
      KillMode = "mixed";
      TimeoutStopSec = 75;
    };

    Install.WantedBy = [ "default.target" ];
  };

  # Global service switching can stop UWSM, so restart only a changed Codex unit.
  home.activation.restartCodex = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
    if ! ${pkgs.diffutils}/bin/cmp --quiet \
      "''${oldGenPath:-}/home-files/.config/systemd/user/codex-app-server.service" \
      "$newGenPath/home-files/.config/systemd/user/codex-app-server.service" 2>/dev/null \
      && env XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" \
        ${pkgs.systemd}/bin/systemctl --user is-active --quiet codex-app-server.service
    then
      run env XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" \
        ${pkgs.systemd}/bin/systemctl --user try-restart codex-app-server.service
    fi
  '';

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.nh.osFlake = "${home}/nix-ops#nixosConfigurations.gaming";
}
