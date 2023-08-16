{ pkgs, ... }: {
  programs.nixvim = {
    plugins.telescope = {
      enable = true;
      extensions.fzf-native.enable = true;

      keymaps = {
        "<leader>ff" = {
          action = "find_files";
          desc = "Find Files";
        };
        "<leader>fz" = {
          action = "current_buffer_fuzzy_find";
          desc = "Find in current buffer";
        };
        "<leader>fr" = {
          action = "oldfiles";
          desc = "Recent Files";
        };
        "<leader>fg" = {
          action = "live_grep";
          desc = "Grep";
        };
        "<leader>fb" = {
          action = "buffers";
          desc = "Buffers";
        };
        "<leader>:" = {
          action = "command_history";
          desc = "Command History";
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
        border = { };
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




