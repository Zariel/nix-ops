{
  config,
  pkgs,
  osConfig,
  inputs,
  ...
}:
let
  go_1_25_6 = pkgs.go_1_25.overrideAttrs (old: rec {
    version = "1.25.6";
    src = pkgs.fetchurl {
      url = "https://go.dev/dl/go${version}.src.tar.gz";
      hash = "sha256-WMv3ceRNdt5vVtGeM7d9dFoeSJNAkih15GWFuXXCsFk=";
    };
  });

  beads = (pkgs.buildGoModule.override { go = go_1_25_6; }) {
    pname = "beads";
    version = "0.52.0";
    src = inputs.beads.outPath;
    subPackages = [ "cmd/bd" ];
    doCheck = false;
    vendorHash = "sha256-M+JCxrKgUxCczYzMc2czLZ/JhdVulo7dH2YLTPrJVSc=";

    postPatch = ''
      goVer="$(go env GOVERSION | sed 's/^go//')"
      sed -i "s/^go .*/go $goVer/" go.mod
    '';

    env.GOTOOLCHAIN = "auto";
    nativeBuildInputs = [
      pkgs.git
      pkgs.pkg-config
    ];
    buildInputs = [ pkgs.icu ];
  };
in
{

  home.packages = with pkgs; [
    wineWow64Packages.full
    winetricks
    vulkan-tools
    p7zip
    unzip
    wget
    unrar
    discord

    # Gaming tools
    gamescope # Valve's gaming compositor for FSR upscaling and frame limiting
    goverlay # GUI for MangoHud configuration
    protontricks # Manage Proton prefixes like winetricks
    # protonup-ng
    # protonup-qt
    umu-launcher
    heroic
    bottles

    # Performance monitoring
    nvtopPackages.amd # GPU monitoring (htop-style for AMD)
    corectrl # AMD GPU/CPU control GUI

    deploy-rs
    obsidian
    # vlc
    mpv

    # makemkv
    dovi-tool
    mediainfo
    ffmpeg
    mkvtoolnix-cli
    rustup
    kubectl
    mkbrr
    # beads
  ];

  programs.anomalyMods = {
    enable = false;
    baseDir = "${config.home.homeDirectory}/games/anomaly";
    versions."v1.5.3" = [
      { name = "gamma"; }
    ];
  };

  programs.lutris = {
    enable = true;
    steamPackage = osConfig.programs.steam.package;
    winePackages = with pkgs; [
      wineWow64Packages.full
    ];
    protonPackages = with pkgs; [
      proton-ge-bin
    ];
    extraPackages = with pkgs; [
      mangohud
      winetricks
      gamescope
      gamemode
      umu-launcher
      vulkan-tools
    ];
  };

  home.shellAliases = {
    k = "kubectl";
  };

  programs.mangohud = {
    enable = true;
    enableSessionWide = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks."*" = {
      identityAgent = "~/.1password/agent.sock";
    };
  };

  programs.ghostty = {
    enable = true;
    settings = {
      theme = "Catppuccin Mocha";
      shell-integration-features = [
        "ssh-env"
      ];
    };
  };

  programs.codex = {
    enable = true;
    package = inputs.codex-cli-nix.packages.${pkgs.system}.default;
    settings = {
      sandbox_mode = "workspace-write";
      sandbox_workspace_write = {
        network_access = true;
      };
    };
  };

  programs.nh.osFlake = "/home/chris/nix-ops#nixosConfigurations.gaming";

  xdg.autostart.enable = true;

  systemd.user.services.onepassword = {
    Unit = {
      Description = "1Password";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.writeShellScript "1password-start" ''
        # Wait for desktop session to fully initialize
        sleep 2
        exec ${pkgs._1password-gui}/bin/1password --silent
      ''}";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
