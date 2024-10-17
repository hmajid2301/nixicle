{pkgs, ...}: {
  programs.nixvim = {
    keymaps = [
      {
        action = "<cmd> Telescope find_files follow=true no_ignore=true hidden=true <CR>";
        key = "<leader>fa";
        options = {
          desc = "Find all files";
        };
        mode = [
          "n"
        ];
      }
    ];

    plugins.telescope = {
      enable = true;
      extensions.fzf-native.enable = true;
      extensions.media-files.enable = true;

      keymaps = {
        "<leader>ff" = {
          action = "find_files";
          options = {
            desc = "Find files";
          };
        };
        "<leader>fm" = {
          action = "keymaps";
          options = {
            desc = "Find keymaps";
          };
        };
        "<leader>fz" = {
          action = "current_buffer_fuzzy_find";

          options = {
            desc = "Find in current buffer";
          };
        };
        "<leader>fr" = {
          action = "oldfiles";

          options = {
            desc = "Recent files";
          };
        };
        "<leader>fg" = {
          action = "live_grep";
          options = {
            desc = "Grep";
          };
        };
        "<leader>fw" = {
          action = "grep_string";
          options = {
            desc = "Search word under cursor";
          };
        };
        "<leader>fb" = {
          action = "buffers";
          options = {
            desc = "Find buffer";
          };
        };
        "<leader>fc" = {
          action = "command_history";

          options = {
            desc = "Search in command history";
          };
        };
      };

      settings = {
        defaults = {
          layout_config = {
            horizontal = {
              prompt_position = "top";
              preview_width = 0.55;
              results_width = 0.8;
            };
            vertical = {
              mirror = false;
            };
            width = 0.87;
            height = 0.80;
            preview_cutoff = 120;
          };
          set_env.COLORTERM = "truecolor";
          prompt_prefix = "   ";
          selection_caret = "  ";
          entry_prefix = "  ";
          color_devicons = true;
          initial_mode = "insert";
          selection_strategy = "reset";
          sorting_strategy = "ascending";

          file_ignore_patterns = [
            "^node_modules/"
            "^.devenv/"
            "^.direnv/"
            "^.git/"
            "^.gitlab-ci-local/"
          ];
          borderchars = [
            "─"
            "│"
            "─"
            "│"
            "╭"
            "╮"
            "╯"
            "╰"
          ];
          border = {};
          layout_strategy = "horizontal";

          vimgrep_arguments = [
            "${pkgs.ripgrep}/bin/rg"
            "-L"
            "--color=never"
            "--no-heading"
            "--with-filename"
            "--line-number"
            "--column"
            "--smart-case"
            "--fixed-strings"
          ];
        };
      };
    };
  };
}
