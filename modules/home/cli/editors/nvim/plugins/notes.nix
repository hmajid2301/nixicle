{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      vim-pencil
      render-markdown-nvim
    ];

    keymaps = [
      {
        action = "<cmd> Telescope find_files search_dirs={\"~/second-brain\"} <CR>";
        key = "<leader>of";
        options = {
          desc = "Find files in second brain";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd> Telescope live_grep search_dirs={\"~/second-brain\"} <CR>";
        key = "<leader>og";
        options = {
          desc = "Search contents in second brain";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd> ObsidianToggleCheckbox <CR>";
        key = "<leader>oc";
        options = {
          desc = "Toggle checkbox";
        };
        mode = [
          "n"
        ];
      }
    ];

    extraConfigLua = ''
      require('render-markdown').setup({
      })
    '';

    plugins = {
      twilight.enable = true;
      zen-mode.enable = true;
      # headlines.enable = true;

      obsidian = {
        enable = true;
        settings = {
          ui = {
            enable = false;
          };
          workspaces = [
            {
              name = "second-brain";
              path = "~/second-brain";
            }
          ];
          dailyNotes = {
            folder = "journal/dailies";
            dateFormat = "%Y-%m-%d";
            aliasFormat = "%B %-d, %Y";
            #template = "daily.md";
          };
          templates = {
            subdir = "templates";
            dateFormat = "%Y-%m-%d";
            timeFormat = "%H:%M";
            substitutions = {};
          };
        };
      };
    };
  };
}
