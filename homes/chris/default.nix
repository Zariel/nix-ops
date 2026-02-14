{
  pkgs,
  ...
}:
{
  imports = [
    ../modules/anomaly-mods.nix
    ./helix.nix
    ./fish.nix
    ./tmux.nix
    # ./firefox.nix
  ];

  home.file = {
    ".ssh/rc".text = ''
      if test "$SSH_AUTH_SOCK" ; then
        ln -sf $SSH_AUTH_SOCK ~/.ssh/ssh_auth_sock
        tmux set-environment -g SSH_AUTH_SOCK ~/.ssh/ssh_auth_sock >/dev/null 2>&1 || true
      fi
    '';
    ".config/MangoHud/MangoHud.conf".text = ''
      blacklist=mpv
    '';
  };

  # Basic home configuration
  home = {
    username = "chris";
    homeDirectory = "/home/chris";
    stateVersion = "25.05";
  };

  # Enable modules
  programs.fd.enable = true;
  programs.bat.enable = true;
  programs.tmux.enable = true;
  programs.fzf.enable = true;
  programs.zoxide.enable = true;
  programs.ripgrep.enable = true;
  programs.eza.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.nh = {
    enable = true;
  };

  programs.codex = {
    enable = true;
  };

  home.packages = with pkgs; [
    doggo
    gnugrep
    gnused
    curlFull
    shellcheck
  ];

  # User-specific git configuration
  programs.git = {
    enable = true;
    settings.user = {
      name = "Chris Bannister";
      email = "c.bannister@gmail.com";
    };
  };

  services.ssh-agent.enable = true;
}
