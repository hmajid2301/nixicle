{config, ...}: {
  programs.nixvim = {
    plugins = {
      lsp.servers.html = {
        enable = true;
        extraOptions.settings = {
          html = {
            format = {
              templating = true;
              wrapLineLength = 120;
              wrapAttributes = "auto";
            };
            hover = {
              documentation = true;
              references = true;
            };
          };
        };
      };

      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          html
        ];
      };
    };
  };
}
