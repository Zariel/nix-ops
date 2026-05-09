{ ... }:

{
  projectRootFile = "flake.nix";

  programs.nixfmt.enable = true;

  settings.excludes = [
    ".codex/**"
    ".tmp-cache/**"
  ];
}
