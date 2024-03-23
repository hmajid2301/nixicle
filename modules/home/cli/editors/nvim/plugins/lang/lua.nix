{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    plugins = {
      lsp.servers.lua-ls.enable = true;

      conform-nvim = {
        formattersByFt = {
          lua = ["stylua"];
        };

        formatters = {
          stylua = {
            command = "${pkgs.stylua}/bin/stylua";
          };
        };
      };

      lint = {
        lintersByFt = {
          lua = ["luacheck"];
        };
        linters = {
          luacheck = {
            cmd = "${pkgs.lua54Packages.luacheck}/bin/luacheck";
          };
        };
      };
      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          lua
          luadoc
          luap
        ];
      };
    };
  };
}
