{ pkgs, ... }: {
  imports = [
    ./ui/statusline.nix
    ./ui/file-explorer.nix
    ./ui/bufferline.nix
  ];

  programs.nixvim = {
    extraPlugins = with pkgs; [
      vimPlugins.nvim-navic
      vimPlugins.nvim-web-devicons
      vimPlugins.barbecue-nvim
      maximize-nvim
    ];

    maps = {
      normal = {
        "<leader>z" = {
          action = "<Cmd>lua require('maximize').toggle()<CR>";
          desc = "Toggle Maximize";
        };
      };
    };

    extraConfigLua =
      # lua
      ''
        require('maximize').setup({default_keymaps = false})
        require("barbecue").setup()
      '';
  };
}
