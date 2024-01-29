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
      {
        action = "<cmd> Telescope frecency <CR>";
        key = "<leader>fR";
        options = {
          desc = "Find most used files";
        };
        mode = [
          "n"
        ];
      }
    ];

    plugins.telescope = {
      enable = true;
      extensions.fzf-native.enable = true;
      extensions.undo.enable = true;
      extensions.frecency.enable = true;

      keymaps = {
        "<leader>ff" = {
          action = "find_files";
          desc = "Find files";
        };
        "<leader>fz" = {
          action = "current_buffer_fuzzy_find";
          desc = "Find in current buffer";
        };
        "<leader>fr" = {
          action = "oldfiles";
          desc = "Recent files";
        };
        "<leader>fg" = {
          action = "live_grep";
          desc = "Grep";
        };
        "<leader>fw" = {
          action = "grep_string";
          desc = "Search word under cursor";
        };
        "<leader>fb" = {
          action = "buffers";
          desc = "Find buffer";
        };
        "<leader>fc" = {
          action = "command_history";
          desc = "Search in command history";
        };
      };

      defaults = {
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
        file_ignore_patterns = [
          "^node_modules/"
          "^.devenv/"
          "^.direnv/"
          "^.git/"
        ];
        prompt_prefix = "   ";
        selection_caret = "  ";
        entry_prefix = "  ";
        color_devicons = true;
        initial_mode = "insert";
        selection_strategy = "reset";
        sorting_strategy = "ascending";
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
      };
    };
  };
}
