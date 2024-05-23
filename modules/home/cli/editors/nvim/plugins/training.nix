{
  pkgs,
  inputs,
  ...
}: let
  precognition-nvim = pkgs.vimUtils.buildVimPlugin {
    version = "latest";
    pname = "precognition.nvim";
    src = inputs.precognition-nvim;
  };
in {
  programs.nixvim = {
    extraPlugins = [
      precognition-nvim
    ];

    extraConfigLua =
      # lua
      ''
        require("precognition").setup({
          startVisible = false,
        })
        require("precognition").hide()
      '';

    keymaps = [
      {
        key = "<leader>vh";
        action =
          # lua
          ''
            function()
              require("precognition").toggle()
              require("hardtime").toggle()
            end
          '';
        options = {
          desc = "Toggle precognition and hardtime";
        };
        mode = [
          "n"
        ];
      }
    ];

    plugins.hardtime = {
      enable = true;
      enabled = false;
    };
  };
}
