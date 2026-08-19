{
  pkgs,
  llm-agents,
  config,
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
    llmAgentPackages.beads-rust
    bd
    formatCommitMessage
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

    matchBlocks."*" = {
      identityAgent = "${home}/.1password/agent.sock";
    };
  };

  programs.codex = {
    enable = true;
    package = llmAgentPackages.codex.overrideAttrs (old: {
      cargoBuildFlags = old.cargoBuildFlags ++ [
        "--package"
        "codex-code-mode-host"
      ];
    });
    settings = {
      sandbox_mode = "workspace-write";
      sandbox_workspace_write = {
        network_access = true;
        writable_roots = [
          "${config.xdg.cacheHome}/go-build"
        ];
      };
      model_reasoning_effort = "high";
      plan_mode_reasoning_effort = "xhigh";
      model_reasoning_summary = "detailed";
      personality = "pragmatic";
      approvals_reviewer = "auto_review";

      features.multi_agent = true;
      features.apps = false;
      skills = {
        draft-commit = ./apps/codex/skills/draft-commit.md;
      };
    };
    context = builtins.readFile ./apps/codex/context.md;
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.nh.osFlake = "${home}/nix-ops#nixosConfigurations.gaming";
}
