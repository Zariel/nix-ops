{ pkgs, osConfig, ... }:
let
  lockCommand = "${pkgs.systemd}/bin/systemctl --user start niri-lock.service";
in
{
  xdg.autostart.enable = true;
  xdg.configFile."niri/config.kdl" = {
    force = true;
    text = ''
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

      hotkey-overlay {
          skip-at-startup
      }

      /-window-rule {
          match app-id=r#"firefox$"#
          exclude title="^Picture-in-Picture$"

          open-fullscreen true
      }

      /-window-rule {
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
          Mod+Alt+L { spawn-sh "${lockCommand}"; }
          Mod+Shift+E { spawn "${pkgs.wlogout}/bin/wlogout"; }
          Mod+Ctrl+Shift+E { quit; }

          Mod+Q { close-window; }
          Mod+F { maximize-column; }
          Mod+Shift+F { fullscreen-window; }
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

  programs.tmux.extraConfig = ''
    # In the local Niri session, copy tmux selections straight to Wayland.
    bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy"
    bind-key -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy"
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
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.niri-firefox = {
    Unit = {
      Description = "Firefox autostart for Niri";
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "XDG_CURRENT_DESKTOP=niri";
    };
    Service = {
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
      ExecStart = "${pkgs.firefox}/bin/firefox";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

}
