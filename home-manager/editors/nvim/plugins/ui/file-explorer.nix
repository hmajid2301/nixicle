{
  programs.nixvim = {
    keymaps = [
      {
        action = "<cmd> Neotree toggle <CR>";
        key = "<leader>e";
        options = {
          desc = "Toggle Tree";
        };
        mode = [
          "n"
        ];
      }
    ];

    plugins.which-key.registrations = {
      "<leader>e" = "+tree";
    };

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
