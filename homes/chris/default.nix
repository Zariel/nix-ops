{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./helix.nix
    ./firefox.nix
  ];

  # Basic home configuration
  home = {
    username = "chris";
    homeDirectory = "/home/chris";
    stateVersion = "25.05";
  };

  # Enable modules
  programs.fish.enable = true;
  programs.tmux.enable = true;
  programs.atuin.enable = true;
  programs.alacritty.enable = true;

  programs.lutris = {
    enable = true;
  };

  programs.nh = {
    enable = true;
    osFlake = "/home/chris/nix-ops#nixosConfigurations.gaming";
  };

  home.packages = with pkgs; [
    doggo
    ripgrep
    gnugrep
    gnused

    curl
    shellcheck

    ghostty
  ];

  # User-specific git configuration
  programs.git = {
    enable = true;
    userName = "Chris Bannister";
    userEmail = "c.bannister@gmail.com";
  };
}
