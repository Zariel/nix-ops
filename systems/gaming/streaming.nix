{
  config,
  pkgs,
  ...
}:

{
  home-manager.users.gaming =
    { ... }:
    {
      home = {
        homeDirectory = "/home/gaming";
        packages = [
          config.programs.steam.package
        ];
        stateVersion = "25.05";
        username = "gaming";
      };

      xdg.autostart.enable = true;
      xdg.configFile = {
        "autostart/lounge-sunshine.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=Lounge Sunshine
          Exec=${pkgs.systemd}/bin/systemctl --user start sunshine.service
          OnlyShowIn=KDE;
          X-KDE-autostart-phase=2
        '';
        "autostart/lounge-steam.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=Lounge Steam
          Exec=${config.programs.steam.package}/bin/steam -silent
          OnlyShowIn=KDE;
          X-KDE-autostart-phase=2
        '';
        "kscreenlockerrc".text = ''
          [Daemon]
          Autolock=false
          LockOnResume=false
          Timeout=0
        '';
        "powerdevilrc".text = ''
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
      };
    };
}
