{
  config,
  pkgs,
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
    settings = {
      legacy_layout = false;
      round_corners = 10;
      background_alpha = 0.8;
      background_color = "1E1E2E";

      font_size = 24;
      text_color = "CDD6F4";
      text_outline_color = "313244";

      pci_dev = "0000:03:00.0";

      gpu_color = "A6E3A1";
      gpu_load_color = [
        "CDD6F4"
        "FAB387"
        "F38BA8"
      ];
      cpu_color = "89B4FA";
      cpu_load_color = [
        "CDD6F4"
        "FAB387"
        "F38BA8"
      ];
      ram_color = "F5C2E7";
      vram_color = "F5C2E7";
      engine_color = "F38BA8";
      wine_color = "F38BA8";
      frametime_color = "A6E3A1";
      fps_color = [
        "F38BA8"
        "F9E2AF"
        "A6E3A1"
      ];

      blacklist = "mpv";
      fps_limit_method = "early";
      toggle_fps_limit = "Shift_L+F1";
    };
  };
}
