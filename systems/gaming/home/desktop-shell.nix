{ pkgs, lib, ... }:
let
  lockCommand = "${pkgs.systemd}/bin/systemctl --user start niri-lock.service";
  keyboardBluetoothNotifications = pkgs.writeShellScript "keyboard-bluetooth-notifications" ''
    set -eu

    device_name="TOTEM"
    device_path="/org/bluez/hci0/dev_ED_29_B4_2A_68_9C"
    pending_property=""

    notify() {
      ${pkgs.libnotify}/bin/notify-send \
        --app-name="Bluetooth" \
        --icon="$1" \
        "$2" \
        "$3"
    }

    ${pkgs.coreutils}/bin/stdbuf -oL ${pkgs.dbus}/bin/dbus-monitor --system \
      "type='signal',sender='org.bluez',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='$device_path'" |
      while IFS= read -r line; do
        case "$line" in
          *'string "Connected"'*)
            pending_property="connected"
            ;;
          *'string "Paired"'*)
            pending_property="paired"
            ;;
          *'boolean true'*)
            case "$pending_property" in
              connected)
                notify bluetooth-active "$device_name connected" "Keyboard is ready"
                ;;
              paired)
                notify bluetooth-active "$device_name paired" "Keyboard pairing saved"
                ;;
            esac
            pending_property=""
            ;;
          *'boolean false'*)
            case "$pending_property" in
              connected)
                notify bluetooth-disabled "$device_name disconnected" "Keyboard connection lost"
                ;;
              paired)
                notify bluetooth-disabled "$device_name unpaired" "Keyboard pairing removed"
                ;;
            esac
            pending_property=""
            ;;
        esac
      done
  '';
  keyboardBluetoothStatus = pkgs.writeShellScript "keyboard-bluetooth-status" ''
    set -eu

    device_name="TOTEM"
    device_path="/org/bluez/hci0/dev_ED_29_B4_2A_68_9C"
    connected="$(${pkgs.systemd}/bin/busctl get-property org.bluez "$device_path" org.bluez.Device1 Connected 2>/dev/null | ${pkgs.gawk}/bin/awk '{ print $2 }' || true)"
    percentage="$(${pkgs.systemd}/bin/busctl get-property org.bluez "$device_path" org.bluez.Battery1 Percentage 2>/dev/null | ${pkgs.gawk}/bin/awk '{ print $2 }' || true)"

    if [ "$connected" = "true" ]; then
      if [ -n "$percentage" ]; then
        text=" $percentage%"
        tooltip="$device_name connected • Battery $percentage%"
        pct="$percentage"
      else
        text=" on"
        tooltip="$device_name connected"
        pct="0"
      fi
      class="connected"
    else
      text=" off"
      tooltip="$device_name disconnected"
      pct="0"
      class="disconnected"
    fi

    ${pkgs.jq}/bin/jq -cn \
      --arg text "$text" \
      --arg tooltip "$tooltip" \
      --arg class "$class" \
      --argjson percentage "$pct" \
      '{ text: $text, tooltip: $tooltip, class: $class, percentage: $percentage }'
  '';
  niriStackStatus = pkgs.writeTextFile {
    name = "niri-stack-status";
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      import html
      import json
      import re
      import subprocess
      import time

      NIRI = "${pkgs.niri}/bin/niri"
      INTERESTING_EVENTS = {
          "WindowsChanged",
          "WindowOpenedOrChanged",
          "WindowClosed",
          "WindowFocusChanged",
          "WindowLayoutsChanged",
          "WorkspaceActiveWindowChanged",
          "WorkspaceActivated",
          "WorkspacesChanged",
      }
      last_payload = None
      windows = []


      def label(window):
          value = window.get("title") or window.get("app_id") or "Window"
          return re.sub(r" {2,}", " ", re.sub(r"[\r\n\t]+", " ", value)).strip()


      def markup_label(window, focused):
          title = html.escape(label(window), quote=False)
          if focused:
              return f'<span foreground="#cdd6f4" weight="bold">‹{title}›</span>'
          return f'<span foreground="#6c7086">{title}</span>'


      def separator():
          return '<span foreground="#45475a">  ·  </span>'


      def timestamp(window):
          ts = window.get("focus_timestamp") or {}
          return (ts.get("secs") or 0) * 1_000_000_000 + (ts.get("nanos") or 0)


      def column_x(window):
          layout = window.get("layout") or {}
          pos = layout.get("pos_in_scrolling_layout")
          if not pos:
              return None
          return pos[0]


      def emit(payload):
          global last_payload
          if payload == last_payload:
              return
          last_payload = payload
          print(json.dumps(payload, separators=(",", ":")), flush=True)


      def empty(text):
          emit({"text": "", "tooltip": text, "class": "empty"})


      def load_windows():
          try:
              result = subprocess.run(
                  [NIRI, "msg", "--json", "windows"],
                  check=True,
                  stdout=subprocess.PIPE,
                  stderr=subprocess.DEVNULL,
                  text=True,
              )
              return json.loads(result.stdout)
          except Exception:
              return None


      def window_for_column(windows, x, focused):
          column = [window for window in windows if column_x(window) == x]
          if any(window.get("id") == focused.get("id") for window in column):
              return focused
          return max(column, key=timestamp)


      def render(current_windows):
          if not current_windows:
              empty("Niri window stack unavailable")
              return

          focused = next((window for window in current_windows if window.get("is_focused")), None)
          if focused is None:
              empty("No focused Niri window")
              return

          focused_x = column_x(focused)
          if focused_x is None:
              title = label(focused)
              emit(
                  {
                      "text": markup_label(focused, True),
                      "tooltip": title,
                      "class": "single",
                  }
              )
              return

          tiled = [
              window
              for window in current_windows
              if window.get("workspace_id") == focused.get("workspace_id")
              and not window.get("is_floating")
              and column_x(window) is not None
          ]
          columns = sorted({column_x(window) for window in tiled})
          left = max((x for x in columns if x < focused_x), default=None)
          right = min((x for x in columns if x > focused_x), default=None)

          stack = []
          if left is not None:
              stack.append(window_for_column(tiled, left, focused))
          stack.append(focused)
          if right is not None:
              stack.append(window_for_column(tiled, right, focused))

          focused_id = focused.get("id")
          parts = [
              markup_label(window, window.get("id") == focused_id)
              for window in stack
          ]
          tooltip = "\n".join(
              (
                  "Focused: " if window.get("id") == focused_id else ""
              )
              + label(window)
              + (
                  f" — {window.get('app_id')}"
                  if window.get("app_id")
                  else ""
              )
              for window in stack
          )

          emit(
              {
                  "text": separator().join(parts),
                  "tooltip": tooltip,
                  "class": "stack" if len(stack) > 1 else "single",
              }
          )


      def replace_window(current_windows, changed):
          changed_id = changed.get("id")
          if changed_id is None:
              return current_windows

          found = False
          updated = []
          for window in current_windows:
              if window.get("id") == changed_id:
                  updated.append(changed)
                  found = True
              else:
                  updated.append(window)

          if not found:
              updated.append(changed)

          return updated


      def remove_window(current_windows, closed):
          closed_id = closed.get("id") if isinstance(closed, dict) else closed
          if closed_id is None:
              return current_windows
          return [window for window in current_windows if window.get("id") != closed_id]


      def refresh_windows():
          loaded = load_windows()
          return loaded if loaded is not None else []


      def watch_events():
          global windows

          while True:
              try:
                  process = subprocess.Popen(
                      [NIRI, "msg", "--json", "event-stream"],
                      stdout=subprocess.PIPE,
                      stderr=subprocess.DEVNULL,
                      text=True,
                      bufsize=1,
                  )
              except Exception:
                  empty("Niri event stream unavailable")
                  time.sleep(2)
                  continue

              assert process.stdout is not None
              for line in process.stdout:
                  try:
                      event = json.loads(line)
                  except json.JSONDecodeError:
                      continue

                  if "WindowsChanged" in event:
                      windows = event["WindowsChanged"].get("windows") or []
                  elif "WindowOpenedOrChanged" in event:
                      changed = event["WindowOpenedOrChanged"].get("window")
                      if changed is not None:
                          windows = replace_window(windows, changed)
                  elif "WindowClosed" in event:
                      windows = remove_window(windows, event["WindowClosed"])
                  elif INTERESTING_EVENTS.intersection(event.keys()):
                      windows = refresh_windows()
                  else:
                      continue

                  render(windows)

              process.wait()
              time.sleep(1)
              windows = refresh_windows()
              render(windows)


      windows = refresh_windows()
      render(windows)
      watch_events()
    '';
  };
in
{
  home.packages = with pkgs; [
    xwayland-satellite
    pavucontrol
    playerctl
    wlogout
    wl-clipboard
    grim
    slurp
  ];

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
        "custom/niri-stack"
      ];
      modules-right = [
        "tray"
        "custom/keyboard"
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

      "custom/niri-stack" = {
        exec = "${niriStackStatus}";
        return-type = "json";
        restart-interval = 5;
        max-length = 120;
        escape = false;
        tooltip = true;
      };

      tray.spacing = 8;

      "custom/keyboard" = {
        exec = "${keyboardBluetoothStatus}";
        return-type = "json";
        interval = 30;
        tooltip = true;
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "muted";
        format-icons.default = [
          ""
          ""
        ];
        scroll-step = 5;
        on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
      };

      clock = {
        format = "{:%a %d %b  %I:%M %p}";
        tooltip-format = "{:%A, %d %B %Y  %I:%M %p}";
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
      #custom-niri-stack,
      #tray,
      #custom-keyboard,
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

      #custom-niri-stack {
        color: #bac2de;
      }

      #custom-niri-stack.stack {
        color: #cdd6f4;
      }

      #pulseaudio.muted {
        color: #f38ba8;
      }

      #custom-keyboard.connected {
        color: #a6e3a1;
      }

      #custom-keyboard.disconnected {
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

      "urgency=low".border-color = "#45475a";
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
          placeholder_text = ''<span foreground="##cdd6f4">$PAMPROMPT</span>'';
          fail_text = ''<span foreground="##f38ba8">Authentication failed</span>'';
        }
      ];

      label = [
        {
          monitor = "";
          text = ''cmd[update:1000] date +"%I:%M %p"'';
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

  systemd.user.services.waybar.Unit.ConditionEnvironment = lib.mkForce "XDG_CURRENT_DESKTOP=niri";

  systemd.user.services.niri-lock = {
    Unit = {
      Description = "Niri lock screen";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };

    Service = {
      Type = "exec";
      ExecStart = "${pkgs.hyprlock}/bin/hyprlock --immediate-render";
      Restart = "no";
    };
  };

  systemd.user.services.keyboard-bluetooth-notifications = {
    Unit = {
      Description = "Notify when the TOTEM keyboard Bluetooth state changes";
      PartOf = [ "graphical-session.target" ];
      After = [
        "graphical-session.target"
        "mako.service"
      ];
    };

    Install.WantedBy = [ "graphical-session.target" ];

    Service = {
      Type = "exec";
      ExecStart = "${keyboardBluetoothNotifications}";
      Restart = "always";
      RestartSec = 2;
    };
  };

  services.swayidle = {
    enable = true;
    events = {
      before-sleep = lockCommand;
      lock = lockCommand;
    };
    timeouts = [
      {
        timeout = 300;
        command = lockCommand;
      }
      {
        timeout = 600;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
      }
    ];
  };
}
