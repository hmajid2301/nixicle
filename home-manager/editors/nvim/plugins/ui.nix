{pkgs, ...}: {
  imports = [
    ./ui/nvim-tree.nix
    ./ui/lualine.nix
    ./ui/bufferline.nix
  ];

  programs.nixvim = {
    extraPlugins = with pkgs; [
      vimPlugins.nvim-web-devicons
      maximize-nvim
    ];

    extraConfigLua =
      # lua
      ''
        require('maximize').setup()
      '';
  };
}
