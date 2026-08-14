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

    # dovi-tool
    mediainfo
    # ffmpeg
    # mkvtoolnix-cli

    zmk-studio
    git-commit-wrapped
    go
    gopls
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
      proton-ge-bin-10
    ];
    extraPackages = with pkgs; [
      mangohud
      winetricks
      gamescope
      osConfig.programs.gamemode.package
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
      # Start with the horizontal summary and cycle only through the layouts
      # defined below: summary, detailed telemetry, and FPS-only.
      preset = [
        2
        4
        1
      ];
      toggle_preset = "Shift_R+F10";
      fps_limit_method = "early";
      toggle_fps_limit = "Shift_L+F1";
    };
  };

  xdg.configFile."MangoHud/presets.conf".text = ''
    # The preset order is configured by `preset` above.

    # 1: FPS-only, in the top-left corner.
    [preset 1]
    legacy_layout=0
    position=top-left
    fps
    fps_only=1
    frametime=0
    frame_timing=0
    cpu_stats=0
    gpu_stats=0

    # 2: Default horizontal summary.
    [preset 2]
    legacy_layout=0
    horizontal
    position=top-left
    fps
    frame_timing
    gpu_stats
    gpu_temp
    cpu_stats
    cpu_temp
    ram
    vram
    engine_version
    wine
    winesync
    arch

    # 4: Detailed hardware and rendering telemetry.
    [preset 4]
    legacy_layout=0
    horizontal=0
    position=top-left
    fps
    frame_timing
    gpu_stats
    gpu_temp
    gpu_core_clock
    cpu_stats
    cpu_temp
    cpu_mhz
    core_load
    ram
    vram
    engine_version
    vulkan_driver
    present_mode
    wine
    winesync
    fsr
  '';
}
