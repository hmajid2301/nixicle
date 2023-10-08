{ pkgs, ... }: {
  imports = [
    ./ui/statusline.nix
    ./ui/file-explorer.nix
    #./ui/bufferline.nix
  ];

  programs.nixvim = {
    extraPlugins = with pkgs; [
      vimPlugins.nui-nvim
      vimPlugins.nvim-web-devicons
      vimPlugins.barbecue-nvim

      # for go.nvim
      vimExtraPlugins.guihua-lua

      # for window-nvim plugin
      vimExtraPlugins.windows-nvim
      vimExtraPlugins.middleclass
      vimExtraPlugins.animation-nvim
    ];

    maps = { };

    extraConfigLua =
      ''
        require("barbecue").setup()

        vim.o.winwidth = 10
        vim.o.winminwidth = 10
        vim.o.equalalways = false
        require('windows').setup()

        -- TODO: move to keymaps
        vim.keymap.set('n', '<C-w>z', '<cmd>WindowsMaximize', {desc = "Maximise current window"})
        vim.keymap.set('n', '<C-w>_', '<cmd>WindowsMaximizeVertically', {desc = "Maximise window vertically"})
        vim.keymap.set('n', '<C-w>|', '<cmd>WindowsMaximizeHorizontally', {desc = "Maximise window horizontally"})
        vim.keymap.set('n', '<C-w>=', '<cmd>WindowsEqualize', {desc = "Maximise window equalize"})
      '';
  };
}
