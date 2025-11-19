{ pkgs, osConfig, ... }:
{

  home.packages = with pkgs; [
    unzip
    wget

    deploy-rs
  ];

}
