{
  config,
  pkgs,
  lib,
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
    # protontricks # Manage Proton prefixes like winetricks
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
    pavucontrol
    playerctl
    wlogout
    wl-clipboard
    grim
    slurp
  ];

  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "mauve";

    fuzzel.enable = true;
    gtk.icon.enable = true;
    mangohud.enable = false;
    mpv.enable = true;
    yazi.enable = true;
    zathura.enable = true;
  };

  gtk.enable = true;

  home.pointerCursor = {
    name = "catppuccin-mocha-mauve-cursors";
    package = pkgs.catppuccin-cursors.mochaMauve;
  };

  home.file.".config/MangoHud/MangoHud.conf".text = lib.mkForce (
    builtins.readFile "${config.catppuccin.sources.mangohud}/mocha/MangoHud.conf"
    + ''

      blacklist=mpv
    ''
  );

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
    systemd.enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 32;
      spacing = 8;
      margin = "6 8 0";

      modules-left = [
        "niri/workspaces"
        "niri/window"
      ];
      modules-right = [
        "tray"
        "pulseaudio"
        "clock"
        "custom/power"
      ];

      "niri/workspaces" = {
        format = "{icon}";
        format-icons = {
          active = "●";
          default = "○";
        };
      };

      "niri/window" = {
        format = "{}";
        max-length = 80;
      };

      tray = {
        spacing = 8;
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "muted";
        format-icons = {
          default = [
            ""
            ""
          ];
        };
        scroll-step = 5;
        on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
      };

      clock = {
        format = "{:%a %d %b  %H:%M}";
        tooltip-format = "{:%A, %d %B %Y  %H:%M}";
      };

      "custom/power" = {
        format = "";
        tooltip = true;
        tooltip-format = "Power menu";
        on-click = "${pkgs.wlogout}/bin/wlogout";
      };
    };
    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free", sans-serif;
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: rgba(17, 17, 27, 0.92);
        color: #cdd6f4;
      }

      #workspaces,
      #window,
      #tray,
      #pulseaudio,
      #clock,
      #custom-power {
        margin: 5px 4px;
        padding: 0 10px;
        background: #1e1e2e;
        border: 1px solid #313244;
        border-radius: 6px;
      }

      #workspaces button {
        padding: 0 5px;
        color: #6c7086;
      }

      #workspaces button.active {
        color: #cba6f7;
      }

      #pulseaudio.muted {
        color: #f38ba8;
      }

      #custom-power {
        color: #f38ba8;
      }
    '';
  };
  services.mako = {
    enable = true;
    settings = {
      font = "JetBrainsMono Nerd Font 10";
      anchor = "top-right";
      width = 360;
      height = 160;
      margin = "12";
      padding = "10";
      border-size = 2;
      border-radius = 6;
      icons = true;
      markup = true;
      default-timeout = 5000;
      background-color = "#1e1e2e";
      text-color = "#cdd6f4";
      border-color = "#cba6f7";
      progress-color = "over #89b4fa";

      "urgency=low" = {
        border-color = "#45475a";
      };

      "urgency=high" = {
        border-color = "#f38ba8";
        default-timeout = 0;
      };
    };
  };
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = true;
      };

      background = [
        {
          monitor = "";
          color = "rgb(17, 17, 27)";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "320, 58";
          position = "0, -60";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(205, 214, 244)";
          inner_color = "rgb(30, 30, 46)";
          outer_color = "rgb(203, 166, 247)";
          check_color = "rgb(137, 180, 250)";
          fail_color = "rgb(243, 139, 168)";
          outline_thickness = 2;
          placeholder_text = ''<span foreground="##cdd6f4">Password</span>'';
          fail_text = ''<span foreground="##f38ba8">Authentication failed</span>'';
        }
      ];

      label = [
        {
          monitor = "";
          text = "$TIME";
          color = "rgb(205, 214, 244)";
          font_size = 64;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 120";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = ''cmd[update:60000] date +"%A, %d %B"'';
          color = "rgb(166, 173, 200)";
          font_size = 18;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 65";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  services.swayidle = {
    enable = true;
    events = {
      before-sleep = "${pkgs.hyprlock}/bin/hyprlock";
      lock = "${pkgs.hyprlock}/bin/hyprlock";
    };
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.hyprlock}/bin/hyprlock";
      }
      {
        timeout = 600;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors";
      }
    ];
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

  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "kvantum";
  };

  catppuccin.kvantum = {
    enable = true;
    flavor = "mocha";
    accent = "mauve";
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

  xdg.autostart.enable = true;
  xdg.configFile."niri/config.kdl" = {
    force = true;
    text =
      let
        steam = osConfig.programs.steam.package;
      in
      ''
          input {
              keyboard {
                  xkb {
                      layout "gb"
                      variant "mac"
                  }
              }
          }

          layout {
              gaps 8
              background-color "#1e1e2e"

              focus-ring {
                  width 3
                  active-color "#cba6f7"
                  inactive-color "#45475a"
                  urgent-color "#f38ba8"
              }

              border {
                  off
                  width 2
                  active-color "#89b4fa"
                  inactive-color "#313244"
                  urgent-color "#f38ba8"
              }

              shadow {
                  on
                  softness 24
                  spread 3
                  offset x=0 y=4
                  color "#11111b80"
                  inactive-color "#11111b50"
              }

              tab-indicator {
                  active-color "#cba6f7"
                  inactive-color "#45475a"
                  urgent-color "#f38ba8"
              }

              insert-hint {
                  color "#fab38780"
              }
          }

          prefer-no-csd

          spawn-at-startup "${pkgs.firefox}/bin/firefox"
          spawn-at-startup "${steam}/bin/steam" "-silent"

          hotkey-overlay {
              skip-at-startup
          }

          window-rule {
              match app-id=r#"firefox$"#
              exclude title="^Picture-in-Picture$"

              open-fullscreen true
          }

          window-rule {
              match app-id=r#"firefox$"# title="^Picture-in-Picture$"

              open-fullscreen false
              open-floating true
              default-column-width { fixed 480; }
              default-window-height { fixed 270; }
          }

        window-rule {
            match app-id=r#"^Alacritty$"#

              draw-border-with-background false
          }

          binds {
              Mod+Shift+Slash { show-hotkey-overlay; }
              Mod+T { spawn "${pkgs.alacritty}/bin/alacritty"; }
              Mod+Return { spawn "${pkgs.ghostty}/bin/ghostty"; }
              Mod+D { spawn "${pkgs.fuzzel}/bin/fuzzel"; }
              Mod+E { spawn "${pkgs.kdePackages.dolphin}/bin/dolphin"; }
              Mod+B { spawn "${pkgs.firefox}/bin/firefox"; }
              Mod+Alt+L { spawn "${pkgs.hyprlock}/bin/hyprlock"; }
              Mod+Shift+E { spawn "${pkgs.wlogout}/bin/wlogout"; }
              Mod+Ctrl+Shift+E { quit; }

              Mod+Q { close-window; }
              Mod+F { fullscreen-window; }
              Mod+V { toggle-window-floating; }
              Mod+O { toggle-overview; }

              Mod+Left  { focus-column-left; }
              Mod+Down  { focus-window-down; }
              Mod+Up    { focus-window-up; }
              Mod+Right { focus-column-right; }
              Mod+H     { focus-column-left; }
              Mod+J     { focus-window-down; }
              Mod+K     { focus-window-up; }
              Mod+L     { focus-column-right; }

              Mod+Ctrl+Left  { move-column-left; }
              Mod+Ctrl+Down  { move-window-down; }
              Mod+Ctrl+Up    { move-window-up; }
              Mod+Ctrl+Right { move-column-right; }
              Mod+Ctrl+H     { move-column-left; }
              Mod+Ctrl+J     { move-window-down; }
              Mod+Ctrl+K     { move-window-up; }
              Mod+Ctrl+L     { move-column-right; }

              Mod+R       { switch-preset-column-width; }
              Mod+Shift+R { switch-preset-column-width-back; }
              Mod+C       { center-column; }

              Mod+Page_Down { focus-workspace-down; }
              Mod+Page_Up   { focus-workspace-up; }
              Mod+U         { focus-workspace-down; }
              Mod+I         { focus-workspace-up; }

              Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
              Mod+Ctrl+Page_Up   { move-column-to-workspace-up; }
              Mod+Ctrl+U         { move-column-to-workspace-down; }
              Mod+Ctrl+I         { move-column-to-workspace-up; }

              Mod+Shift+Page_Down { move-workspace-down; }
              Mod+Shift+Page_Up   { move-workspace-up; }
              Mod+Shift+U         { move-workspace-down; }
              Mod+Shift+I         { move-workspace-up; }

              Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
              Mod+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }

              Print { screenshot; }
              Ctrl+Print { screenshot-screen; }
              Alt+Print { screenshot-window; }

              XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"; }
              XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"; }
              XF86AudioMute allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
              XF86AudioMicMute allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }
              XF86AudioPlay allow-when-locked=true { spawn "${pkgs.playerctl}/bin/playerctl" "play-pause"; }
              XF86AudioNext allow-when-locked=true { spawn "${pkgs.playerctl}/bin/playerctl" "next"; }
              XF86AudioPrev allow-when-locked=true { spawn "${pkgs.playerctl}/bin/playerctl" "previous"; }
          }
      '';
  };

  xdg = {
    enable = true;
    mimeApps.enable = true;
    mimeApps.defaultApplications = {
      "inode/directory" = [ "org.kde.dolphin.desktop" ];

      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "text/html" = [ "firefox.desktop" ];

      "image/jpeg" = [ "org.kde.gwenview.desktop" ];
      "image/png" = [ "org.kde.gwenview.desktop" ];
      "image/gif" = [ "org.kde.gwenview.desktop" ];
      "image/webp" = [ "org.kde.gwenview.desktop" ];
      "application/pdf" = [ "org.kde.okular.desktop" ];

      "application/zip" = [ "org.kde.ark.desktop" ];
      "application/x-7z-compressed" = [ "org.kde.ark.desktop" ];
      "application/x-rar" = [ "org.kde.ark.desktop" ];
      "application/x-tar" = [ "org.kde.ark.desktop" ];
      "application/gzip" = [ "org.kde.ark.desktop" ];

      "text/plain" = [
        "org.kde.kate.desktop"
        "org.kde.kwrite.desktop"
      ];
      "application/json" = [
        "org.kde.kate.desktop"
        "org.kde.kwrite.desktop"
      ];

      "audio/mpeg" = [ "mpv.desktop" ];
      "audio/flac" = [ "mpv.desktop" ];
      "audio/ogg" = [ "mpv.desktop" ];
      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ];
      "video/webm" = [ "mpv.desktop" ];
    };
  };
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
