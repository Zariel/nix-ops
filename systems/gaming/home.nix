{
  config,
  pkgs,
  osConfig,
  ...
}:
{

  home.packages = with pkgs; [
    wineWowPackages.full
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

    # Performance monitoring
    nvtopPackages.amd # GPU monitoring (htop-style for AMD)
    corectrl # AMD GPU/CPU control GUI

    deploy-rs
    obsidian
    vlc

    makemkv
    dovi-tool
    mediainfo
    ffmpeg
    mkvtoolnix-cli
  ];

  programs.anomalyMods = {
    enable = true;
    baseDir = "${config.home.homeDirectory}/games/anomaly";
    versions."v1.5.3" = [
      { name = "gamma"; }
    ];
  };

  programs.lutris = {
    enable = true;
    steamPackage = osConfig.programs.steam.package;
    winePackages = with pkgs; [
      wineWowPackages.full
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

  programs.mangohud = {
    enable = true;
    enableSessionWide = true;
  };

  programs.ssh = {
    enable = true;

    matchBlocks."*" = {
      identityAgent = "~/.1password/agent.sock";
    };
  };

  programs.ghostty = {
    enable = true;
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
