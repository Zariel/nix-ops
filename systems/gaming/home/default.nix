{
  pkgs,
  inputs,
  ...
}:
let
  llm-agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  beadsPackage = llm-agents.beads;

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
    llm-agents.beads-rust
    bd
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
      identityAgent = "~/.1password/agent.sock";
    };
  };

  programs.codex = {
    enable = true;
    package = llm-agents.codex.overrideAttrs (old: {
      cargoBuildFlags = old.cargoBuildFlags ++ [
        "--package"
        "codex-code-mode-host"
      ];
    });
    settings = {
      sandbox_mode = "workspace-write";
      # sandbox_workspace_write = {
      #   network_access = true;
      #   writable_roots = [
      #     "/dev/kvm"
      #   ];
      # };
      model_reasoning_effort = "high";
      plan_mode_reasoning_effort = "xhigh";
      model_reasoning_summary = "detailed";
      personality = "pragmatic";
      approvals_reviewer = "auto_review";

      features.multi_agent = true;
      features.apps = false;
    };
    context = ''
      ## Solution-space discipline
        Optimize for choosing the right problem and ownership model before optimizing
      an implementation.

      For cheaply reversible implementation decisions, proceed directly.

      Before making a decision that is expensive to reverse, first identify the
      actual requirement and hard constraints, independently of the current code.

      Then explore materially different solution families before selecting one.
      In particular consider whether the requirement can be satisfied by:

      - removing the mechanism entirely
      - delegating responsibility to an existing primitive
      - solving the problem at a different layer
      - changing the interface so the problem disappears
      - deriving state instead of storing or reconciling it
      - using a standard mechanism instead of custom machinery

      Do not generate alternatives merely for completeness. Explore when the
      decision has meaningful cost of reversal or significant uncertainty.

      For especially consequential architectural decisions, prefer independent
      solution proposals before selecting an approach rather than asking one
      proposal to critique itself.

      After implementation begins, reopen the architectural decision when new
      information materially changes an assumption or complexity grows beyond what
      the chosen model predicted.

      At that point, do not merely simplify the implementation. Ask whether the
      chosen solution family is still correct.
    '';
    # rules.default = ''
    #   prefix_rule(pattern=["kubectl"], decision="allow")
    #   prefix_rule(pattern=["cargo", "test"], decision="allow")
    #   prefix_rule(pattern=["nix", "eval"], decision="allow")
    #   prefix_rule(pattern=["nix", "build"], decision="allow")
    #   prefix_rule(pattern=["nix", "fmt"], decision="allow")
    #   prefix_rule(pattern=["nix", "shell"], decision="allow")
    #   prefix_rule(pattern=["mkosi", "-f", "build"], decision="allow")
    #   prefix_rule(pattern=["mkosi"], decision="allow")
    #   prefix_rule(pattern=["nix", "develop"], decision="allow")
    #   prefix_rule(pattern=["git", "add"], decision="allow")
    #   prefix_rule(pattern=["git", "commit-wrapped"], decision="allow")
    #   prefix_rule(pattern=["rg"], decision="allow")
    #   prefix_rule(pattern=["bd"], decision="allow")
    #   prefix_rule(pattern=["podman"], decision="allow")
    # '';
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.nh.osFlake = "/home/chris/nix-ops#nixosConfigurations.gaming";
}
