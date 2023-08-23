{pkgs, ...}: {
  imports = [
    ./ui/nvim-tree.nix
    ./ui/lualine.nix
    ./ui/bufferline.nix
  ];

  programs.nixvim = {
    extraPlugins = with pkgs; [
      vimPlugins.nvim-web-devicons
      windex-nvim
    ];

    extraConfigLua =
      # lua
      ''
        require('windex').setup {
              extra_keymaps = true,
              save_buffers = true,
            }
      '';
  };
}
