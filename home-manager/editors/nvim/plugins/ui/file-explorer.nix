{
  programs.nixvim = {
    keymaps = [
      {
        action = "<cmd>lua MiniFiles.open()<cr>";
        key = "<leader>e";
        options = {
          desc = "Open File Tree";
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
        lspRenameAutosave = true;
        bufOptions = {
          buflisted = true;
          bufhidden = "hide";
        };
        viewOptions = {
          showHidden = true;
        };
      };
    };
  };
}
