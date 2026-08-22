{ pkgs }:
pkgs.writeShellApplication {
  name = "power-menu";
  runtimeInputs = [
    pkgs.fuzzel
    pkgs.niri
    pkgs.systemd
  ];
  text = ''
    choice="$(
      printf '%s\n' \
        '  Lock' \
        '󰤄  Suspend' \
        '󰍃  Log out' \
        '  Reboot' \
        '  Power off' |
        fuzzel --dmenu \
          --prompt='Session  ' \
          --lines=5 \
          --minimal-lines \
          --width=24 \
          --no-sort \
          --only-match
    )" || exit 0

    case "$choice" in
      '  Lock') systemctl --user start niri-lock.service ;;
      '󰤄  Suspend') systemctl suspend ;;
      '󰍃  Log out') niri msg action quit --skip-confirmation ;;
      '  Reboot') systemctl reboot ;;
      '  Power off') systemctl poweroff ;;
    esac
  '';
}
