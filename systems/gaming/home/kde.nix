{ pkgs, ... }:
{
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
}
