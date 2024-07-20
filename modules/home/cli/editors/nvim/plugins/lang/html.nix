{config, ...}: {
  programs.nixvim = {
    files = {
      "ftplugin/html.lua" = {
        opts = {
          expandtab = true;
          shiftwidth = 4;
          tabstop = 4;
        };
      };
    };

    plugins = {
      lsp.servers = {
        htmx = {
          enable = true;
        };

        html = {
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
      };

      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          html
        ];
      };
    };
  };
}
