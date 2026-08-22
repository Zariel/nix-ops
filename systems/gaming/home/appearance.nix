{ pkgs, lib, ... }:
{
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
  home.file."/home/chris/.gtkrc-2.0".force = lib.mkForce true;

  home.pointerCursor = {
    name = "catppuccin-mocha-mauve-cursors";
    package = pkgs.catppuccin-cursors.mochaMauve;
  };

  programs.alacritty = {
    enable = true;
    theme = "catppuccin_mocha";
    settings.window.decorations = "None";
  };

  programs.fuzzel.enable = true;

  programs.ghostty = {
    enable = true;
    systemd.enable = true;
    settings = {
      theme = "Catppuccin Mocha";
      shell-integration-features = [
        "ssh-env"
      ];
    };
  };

  xdg.configFile."systemd/user/app-com.mitchellh.ghostty.service.d/session.conf".text = ''
    [Unit]
    PartOf=graphical-session.target
  '';
}
