{
  programs.nixvim = {
    maps = {
      normal = {
        "<leader>e" = {
          desc = "Toggle Tree";
          action = "<cmd> NvimTreeToggle <CR>";
        };
      };
    };

    extraConfigLua =
      # lua
      ''
        require("which-key").register({
          ["<leader>e"] = { name = "+tree" },
        })
      '';

    plugins.nvim-tree = {
      enable = true;
      disableNetrw = true;
      hijackNetrw = true;
      hijackCursor = true;
      syncRootWithCwd = true;

      updateFocusedFile = {
        enable = true;
      };

      git = {
        ignore = false;
      };

      view = {
        preserveWindowProportions = true;
      };

      renderer = {
        indentMarkers = {
          enable = true;
        };

        icons = {
          show = {
            file = true;
            folder = true;
            folderArrow = true;
            git = false;
          };

          glyphs = {
            default = "󰈚";
            symlink = "";
            folder = {
              default = "";
              empty = "";
              emptyOpen = "";
              open = "󰝰";
              symlink = "";
              symlinkOpen = "";
              arrowOpen = "";
              arrowClosed = "";
            };
            git = {
              unstaged = "✗";
              staged = "✓";
              unmerged = "";
              renamed = "➜";
              untracked = "★";
              deleted = "";
              ignored = "◌";
            };
          };
        };
      };
    };
  };
}
