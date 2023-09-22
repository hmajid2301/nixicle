{ pkgs, ... }: {
  imports = [
    ./ui/statusline.nix
    ./ui/file-explorer.nix
    ./ui/bufferline.nix
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
    ];

    maps = { };

    extraConfigLua =
      # lua
      ''
        require("barbecue").setup()
        require('windows').setup()
      '';
  };
}
