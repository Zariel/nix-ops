{
  config,
  pkgs,
  osConfig,
  inputs,
  ...
}:
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
    # heroic
    # bottles

    # Performance monitoring
    nvtopPackages.amd # GPU monitoring (htop-style for AMD)
    corectrl # AMD GPU/CPU control GUI

    deploy-rs
    obsidian
    # vlc
    mpv
    bubblewrap

    # makemkv
    dovi-tool
    mediainfo
    ffmpeg
    mkvtoolnix-cli
    rustup
    kubectl
    mkbrr
    xwayland-satellite
  ];

  catppuccin = {
    enable = true;
    flavor = "mocha";

    mangohud.enable = false;
  };

  programs.alacritty = {
    enable = true;
    theme = "catppuccin_mocha";
    settings.window.decorations = "None";
  };
  programs.fuzzel = {
    enable = true;
  };
  programs.waybar = {
    enable = true;
  };
  services.mako = {
    enable = true;
  };

  # programs.chromium.enable = true;

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
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
    settings = {
      sandbox_mode = "workspace-write";
      sandbox_workspace_write = {
        network_access = true;
      };
    };
  };

  programs.nh.osFlake = "/home/chris/nix-ops#nixosConfigurations.gaming";

  xdg.autostart.enable = true;
  # xdg.configFile."niri/config.kdl".text =
  #   let
  #     steam = osConfig.programs.steam.package;
  #   in
  #   ''
  #     input {
  #         keyboard {
  #             xkb {
  #                 layout "gb"
  #                 variant "mac"
  #             }
  #         }
  #     }

  #     layout {
  #         gaps 8
  #         background-color "#1e1e2e"

  #         focus-ring {
  #             width 3
  #             active-color "#cba6f7"
  #             inactive-color "#45475a"
  #             urgent-color "#f38ba8"
  #         }

  #         border {
  #             off
  #             width 2
  #             active-color "#89b4fa"
  #             inactive-color "#313244"
  #             urgent-color "#f38ba8"
  #         }

  #         shadow {
  #             on
  #             softness 24
  #             spread 3
  #             offset x=0 y=4
  #             color "#11111b80"
  #             inactive-color "#11111b50"
  #         }

  #         tab-indicator {
  #             active-color "#cba6f7"
  #             inactive-color "#45475a"
  #             urgent-color "#f38ba8"
  #         }

  #         insert-hint {
  #             color "#fab38780"
  #         }
  #     }

  #     prefer-no-csd

  #     spawn-at-startup "${pkgs.waybar}/bin/waybar"
  #     spawn-at-startup "${pkgs.xwayland-satellite}/bin/xwayland-satellite"
  #     spawn-at-startup "${pkgs.firefox}/bin/firefox"
  #     spawn-at-startup "${steam}/bin/steam" "-silent"

  #     hotkey-overlay {
  #         skip-at-startup
  #     }

  #     window-rule {
  #         match app-id=r#"firefox$"#
  #         exclude title="^Picture-in-Picture$"

  #         open-fullscreen true
  #     }

  #     window-rule {
  #         match app-id=r#"firefox$"# title="^Picture-in-Picture$"

  #         open-fullscreen false
  #         open-floating true
  #         default-column-width { fixed 480; }
  #         default-window-height { fixed 270; }
  #     }

  #     window-rule {
  #         match app-id=r#"(?i)^(steam|steamwebhelper)$"#

  #         open-fullscreen true
  #     }

  #     window-rule {
  #         match app-id=r#"^Alacritty$"#

  #         draw-border-with-background false
  #     }

  #     binds {
  #         Mod+Shift+Slash { show-hotkey-overlay; }
  #         Mod+T { spawn "alacritty"; }
  #         Mod+D { spawn "fuzzel"; }

  #         Mod+Q { close-window; }
  #         Mod+F { fullscreen-window; }
  #         Mod+Shift+E { quit; }

  #         Mod+Left  { focus-column-left; }
  #         Mod+Down  { focus-window-down; }
  #         Mod+Up    { focus-window-up; }
  #         Mod+Right { focus-column-right; }
  #         Mod+H     { focus-column-left; }
  #         Mod+J     { focus-window-down; }
  #         Mod+K     { focus-window-up; }
  #         Mod+L     { focus-column-right; }

  #         Mod+Ctrl+Left  { move-column-left; }
  #         Mod+Ctrl+Down  { move-window-down; }
  #         Mod+Ctrl+Up    { move-window-up; }
  #         Mod+Ctrl+Right { move-column-right; }
  #         Mod+Ctrl+H     { move-column-left; }
  #         Mod+Ctrl+J     { move-window-down; }
  #         Mod+Ctrl+K     { move-window-up; }
  #         Mod+Ctrl+L     { move-column-right; }

  #         Mod+R       { switch-preset-column-width; }
  #         Mod+Shift+R { switch-preset-column-width-back; }
  #         Mod+C       { center-column; }

  #         Mod+Page_Down { focus-workspace-down; }
  #         Mod+Page_Up   { focus-workspace-up; }
  #         Mod+U         { focus-workspace-down; }
  #         Mod+I         { focus-workspace-up; }

  #         Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
  #         Mod+Ctrl+Page_Up   { move-column-to-workspace-up; }
  #         Mod+Ctrl+U         { move-column-to-workspace-down; }
  #         Mod+Ctrl+I         { move-column-to-workspace-up; }

  #         Mod+Shift+Page_Down { move-workspace-down; }
  #         Mod+Shift+Page_Up   { move-workspace-up; }
  #         Mod+Shift+U         { move-workspace-down; }
  #         Mod+Shift+I         { move-workspace-up; }

  #         Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
  #         Mod+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }

  #         XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"; }
  #         XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"; }
  #         XF86AudioMute allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
  #         XF86AudioMicMute allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }
  #     }
  #   '';
  xdg.configFile."powerdevilrc".text = ''
    [AC][Display]
    DimDisplayIdleTimeoutSec=-1
    DimDisplayWhenIdle=false
    TurnOffDisplayIdleTimeoutSec=-1
    TurnOffDisplayIdleTimeoutWhenLockedSec=-1

    [AC][Performance]
    PowerProfile=performance

    [AC][SuspendAndShutdown]
    AutoSuspendAction=0
  '';
  xdg.configFile."kscreenlockerrc".text = ''
    [Daemon]
    Autolock=false
    LockOnResume=false
    Timeout=0
  '';

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
