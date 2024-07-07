{
  pkgs,
  lib,
  ...
}: {
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  programs.nixvim = {
    plugins.barbecue.enable = true;

    keymaps = [
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

    # TODO: can we remove
    extraPlugins = with pkgs; [
      vimPlugins.nui-nvim
      vimPlugins.nvim-web-devicons
      vimPlugins.dressing-nvim
    ];
  };
}
