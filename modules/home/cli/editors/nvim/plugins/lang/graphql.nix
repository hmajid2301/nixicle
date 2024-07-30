{config, ...}: {
  programs.nixvim = {
    files = {
      "ftplugin/graphql.lua" = {
        opts = {
          expandtab = true;
          shiftwidth = 2;
          tabstop = 2;
        };
      };
    };

    plugins = {
      lsp.servers = {
        graphql = {
          enable = true;
        };
      };

      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          graphql
        ];
      };
    };
  };
}
