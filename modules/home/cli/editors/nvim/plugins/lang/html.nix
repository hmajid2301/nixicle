{
  config,
  pkgs,
  ...
}: {
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
      conform-nvim = {
        formattersByFt = {
          html = ["htmlbeautifier" "rustywind"];
        };

        formatters = {
          htmlbeautifier = {
            command = "${pkgs.rubyPackages.htmlbeautifier}/bin/htmlbeautifier";
          };
        };
      };

      lsp.servers = {
        htmx = {
          enable = true;
        };

        html = {
          enable = true;
          filetypes = ["html"];
          settings = {
            html = {
              format = {
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
