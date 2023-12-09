{ pkgs, ... }: {
  imports = [
    ./coding/cmp.nix
  ];

  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      friendly-snippets
    ];

    extraConfigLua =
      # lua
      ''
        -- autopairs
        local cmp_autopairs = require('nvim-autopairs.completion.cmp')
        local cmp = require('cmp')
        cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

        require("luasnip.loaders.from_vscode").lazy_load()
      '';


    plugins = {
      mini = {
        enable = true;
        modules = {
          surround = { };
          comment = { };
        };

      };
      luasnip = {
        enable = true;
      };

      nvim-autopairs = {
        enable = true;
        disabledFiletypes = [ "TelescopePrompt" "vim" ];
      };

      comment-nvim = {
        enable = true;
      };
    };
  };
}
