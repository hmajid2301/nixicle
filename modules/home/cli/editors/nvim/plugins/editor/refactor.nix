{
  programs.nixvim = {
    keymaps = [
      {
        action = "<cmd>Refactor extract<cr>";
        key = "<leader>re";
        options = {
          desc = "Refactor extract";
        };
        mode = [
          "x"
        ];
      }
      {
        action = "<cmd>Refactor extract_to_file<cr>";
        key = "<leader>rf";
        options = {
          desc = "Refactor extract to file";
        };
        mode = [
          "x"
        ];
      }
      {
        action = "<cmd>Refactor extract_var<cr>";
        key = "<leader>rv";
        options = {
          desc = "Refactor variable";
        };
        mode = [
          "x"
        ];
      }
      {
        action = "<cmd>Refactor inline_var<cr>";
        key = "<leader>ri";
        options = {
          desc = "Refactor inline variable";
        };
        mode = [
          "x"
          "n"
        ];
      }
      {
        action = "<cmd>Refactor inline_func<cr>";
        key = "<leader>rI";
        options = {
          desc = "Refactor inline function";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>Refactor extract_block<cr>";
        key = "<leader>rb";
        options = {
          desc = "Refactor extract block";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>Refactor extract_block_to_file<cr>";
        key = "<leader>rbf";
        options = {
          desc = "Refactor extract block to file";
        };
        mode = [
          "n"
        ];
      }
    ];

    plugins = {
      refactoring = {
        enable = true;
      };
    };
  };
}
