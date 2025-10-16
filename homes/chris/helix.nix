{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.helix = {
    enable = true;
    defaultEditor = true;

    settings = {
      theme = "penumbra+";

      editor = {
        end-of-line-diagnostics = "hint";

        inline-diagnostics = {
          cursor-line = "error";
        };

        soft-wrap = {
          enable = true;
        };
      };

      keys.normal = {
        "C-d" = [
          "move_prev_word_start"
          "move_next_word_end"
          "search_selection"
          "extend_search_next"
        ];
      };
    };

    languages = {
      language-server = {
        gopls.config = {
          "formatting.gofumpt" = true;
        };

        ltex-ls.config.ltex = {
          language = "en-GB";
        };

        nil = {
          command = "nil";
        };
      };

      language = [
        {
          name = "latex";
          language-servers = [
            "texlab"
            "ltex-ls"
          ];
        }
        {
          name = "go";
          auto-format = true;
        }
        {
          name = "python";
          formatter = {
            command = "ruff";
            args = [
              "format"
              "--line-length"
              "88"
              "-"
            ];
          };
          auto-format = true;
        }
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = "nixfmt";
            args = [ ];
          };
          language-servers = [ "nil" ];
        }
      ];
    };
  };

  # Install language servers
  home.packages = with pkgs; [
    # Language servers
    nil
    gopls
    texlab
    ltex-ls
    ruff
    pyright

    # Formatters
    nixfmt-rfc-style
  ];
}
