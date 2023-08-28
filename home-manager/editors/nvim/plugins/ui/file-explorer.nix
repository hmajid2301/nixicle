{
  programs.nixvim = {
    maps = {
      normal = {
        "<leader>e" = {
          desc = "Toggle Tree";
          action = "<cmd> Neotree toggle <CR>";
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

    plugins.neo-tree = {
      enable = true;
      filesystem = {
        followCurrentFile = {
          enabled = true;
        };

        filteredItems = {
          visible = true;
          hideDotfiles = false;
          hideByName = [
            ".git"
            "node_modules"
          ];
        };
      };

      defaultComponentConfigs = {
        gitStatus = {
          symbols = {
            untracked = "★";
            ignored = "◌";
            unstaged = "✗";
            staged = "✓";
          };
        };
        indent = {
          expanderCollapsed = "";
          expanderExpanded = "";
          withExpanders = true;
        };
      };
    };
  };
}
