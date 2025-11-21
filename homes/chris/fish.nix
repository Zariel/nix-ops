{ pkgs, ... }:
{
  programs.fish = {
    plugins = [
      # {
      #   name = "z";
      #   src = pkgs.fishPlugins.z.src;
      # }
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair.src;
      }
    ];

    shellAliases = {
      fcd = "cd (fd --type directory | fzf)";
    };

  };
}
