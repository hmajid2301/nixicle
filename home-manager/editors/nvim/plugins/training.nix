{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      hardtime-nvim
    ];

    maps = {
      normal = {
        "<leader>vtt" = {
          action = "<cmd>Hardtime toggle<cr>";
          desc = "Toggle hardtime";
        };
      };
    };

    extraConfigLua =
      # lua
      ''
        require("hardtime").setup({
        	enabled = false,
        })
      '';
  };
}
