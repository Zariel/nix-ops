{ pkgs, ... }:
{
  programs.mangohud = {
    enable = true;
    enableSessionWide = true;
  };

  programs.ssh = {
    enable = true;

    matchBlocks."*" = {
      identityAgent = "~/.1password/agent.sock";
    };
  };

  programs.claude-code.enable = true;

  xdg.autostart.enable = true;
}
