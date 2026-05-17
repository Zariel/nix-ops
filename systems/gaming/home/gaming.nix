{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
{
  home.packages = with pkgs; [
    wineWow64Packages.full
    winetricks
    vulkan-tools
    discord

    gamescope
    goverlay
    umu-launcher

    nvtopPackages.amd
    corectrl

    dovi-tool
    mediainfo
    ffmpeg
    mkvtoolnix-cli

    zmk-studio
  ];

  home.file.".config/MangoHud/MangoHud.conf".text = lib.mkForce (
    builtins.readFile "${config.catppuccin.sources.mangohud}/mocha/MangoHud.conf"
    + ''

      blacklist=mpv
    ''
  );

  programs.anomalyMods = {
    enable = false;
    baseDir = "${config.home.homeDirectory}/games/anomaly";
    versions."v1.5.3" = [
      { name = "gamma"; }
    ];
  };

  programs.lutris = {
    # enable = true;
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

  programs.mangohud = {
    enable = true;
    enableSessionWide = true;
  };
}
