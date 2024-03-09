{pkgs, ...}: {
  imports = [
    ./ui/statusline.nix
    ./ui/file-explorer.nix
  ];

  programs.nixvim = {
    plugins.barbecue.enable = true;
    # plugins.noice.enable = true;
    plugins.which-key.registrations = {
      "<C-w>" = "+windows";
      "b" = "+buffers";
    };

    keymaps = [
      {
        action = "<cmd>WindowsMaximize<cr>";
        key = "<C-w>z";
        options = {
          desc = "Maximise current window";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>WindowsMaximizeVertically<cr>";
        key = "<C-w>|";
        options = {
          desc = "Maximise window vertically";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>WindowsMaximizeHorizontally<cr>";
        key = "<C-w>-";
        options = {
          desc = "Maximise window horizontally";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>WindowsEqualize<cr>";
        key = "<C-w>=";
        options = {
          desc = "Maximise window equalise";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>bufdo bd<cr>";
        key = "<leader>ba";
        options = {
          desc = "Close all buffers";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>Bdelete<cr>";
        key = "<leader>bd";
        options = {
          desc = "Close current buffer";
        };
        mode = [
          "n"
        ];
      }
    ];

    extraPlugins = with pkgs; [
      vimPlugins.nui-nvim
      vimPlugins.nvim-web-devicons
      vimPlugins.dressing-nvim
    ];
  };
}
