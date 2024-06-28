{
  pkgs,
  inputs,
  ...
}: let
  maximize-nvim = pkgs.vimUtils.buildVimPlugin {
    version = "latest";
    pname = "maximize.nvim";
    src = inputs.maximize-nvim;
  };
in {
  programs.nixvim = {
    keymaps = [
      {
        action = "<cmd>Maximize<cr>";
        key = "<leader>z";
        options = {
          desc = "Toggle maximize window";
        };
        mode = [
          "n"
        ];
      }
    ];
    extraPlugins = [
      maximize-nvim
    ];

    extraConfigLua = ''
      require("maximize").setup()
    '';
  };
}
