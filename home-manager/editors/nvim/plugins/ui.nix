{ pkgs, ... }: {
  imports = [
    ./ui/statusline.nix
    ./ui/file-explorer.nix
    #./ui/bufferline.nix
  ];

  programs.nixvim = {
    extraPlugins = with pkgs; [
      vimPlugins.nvim-navic
      vimPlugins.nui-nvim
      vimPlugins.nvim-web-devicons
      vimPlugins.barbecue-nvim

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
      '';
  };
}
