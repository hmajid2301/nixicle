{ pkgs, ... }: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      hardtime-nvim
    ];

    extraConfigLua =
      # lua
      ''
        require("hardtime").setup({
        	enabled = false,
        })
      '';
  };
}
