{ pkgs, ... }: {
  imports = [
    ./ui/statusline.nix
    ./ui/file-explorer.nix
    # ./ui/bufferline.nix
  ];

  programs.nixvim = {
    plugins.barbecue.enable = true;
    plugins.which-key.registrations = {
      "<C-w>" = "+windows";
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
        action = "<cmd>WindowsEqualize";
        key = "<C-w>=";
        options = {
          desc = "Maximise window equalise";
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

      # for go.nvim
      vimExtraPlugins.guihua-lua

      # for window-nvim plugin
      vimExtraPlugins.windows-nvim
      vimExtraPlugins.middleclass
      vimExtraPlugins.animation-nvim
    ];

    extraConfigLua =
      ''
        vim.o.winwidth = 10
        vim.o.winminwidth = 10
        vim.o.equalalways = false
        require('windows').setup()
      '';
  };
}
