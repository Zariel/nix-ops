{
  pkgs,
  inputs,
  ...
}:
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
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
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

      features.multi_agent = true;
      features.apps = false;
    };
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

  programs.nh.osFlake = "/home/chris/nix-ops#nixosConfigurations.gaming";
}
