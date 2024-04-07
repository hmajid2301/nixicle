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
        settings = {
          delete_to_trash = true;
          use_default_keymaps = true;
          lsp_file_method.autosave_changes = true;
          buf_options = {
            buflisted = true;
            bufhidden = "hide";
          };
          view_options = {
            show_hidden = true;
          };
        };
      };
    };
  };
}
