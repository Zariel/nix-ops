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
      sandbox_workspace_write = {
        network_access = true;
      };
      model_reasoning_effort = "high";
      plan_mode_reasoning_effort = "xhigh";
      model_reasoning_summary = "detailed";
      personality = "pragmatic";

      features.multi_agent = true;
    };
  };

  programs.nh.osFlake = "/home/chris/nix-ops#nixosConfigurations.gaming";
}
