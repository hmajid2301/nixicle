{
  programs.nixvim = {
    plugins.which-key = {
      enable = true;
    };
    extraConfigLua =
      # lua
      ''
        defaults = {
          mode = { "n", "v" },
          ["<leader>f"] = { name = "+file/find" },
          ["<leader>d"] = { name = "+debug" },
        }
        local wk = require("which-key")
        wk.register(defaults)
      '';
  };
}
