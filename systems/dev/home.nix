{ pkgs, ... }:
{

  home.packages = with pkgs; [
    unzip
    wget

    deploy-rs
  ];

  programs.helix.settings.editor.true-color = true;
}
