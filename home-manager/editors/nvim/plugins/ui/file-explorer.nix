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
      {
        action = "<cmd> Oil <CR>";
        key = "-";
        options = {
          desc = "Open parent directory";
        };
        mode = [
          "n"
        ];
      }
    ];

    plugins = {
      which-key.registrations = {
        "<leader>e" = "+tree";
      };

      oil = {
        enable = true;
        deleteToTrash = true;
        useDefaultKeymaps = true;
        # lspRenameAutosave = true;
        # bufOptions = {
        #   buflisted = true;
        #   bufhidden = "hide";
        # };
        viewOptions = {
          showHidden = true;
        };
      };

      neo-tree = {
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
  };
}
