{
  config,
  pkgs,
  ...
}: {
  xdg.configFile."nvim/queries/html/injections.scm".text = builtins.readFile ./lua/html/injections.scm;

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
        settings = {
          formatters_by_ft = {
            html = ["htmlbeautifier" "rustywind"];
          };

          formatters = {
            htmlbeautifier = {
              command = "${pkgs.rubyPackages.htmlbeautifier}/bin/htmlbeautifier";
            };
          };
        };
      };

      lsp.servers = {
        htmx = {
          enable = true;
        };

        html = {
          enable = true;
          filetypes = ["html" "templ"];
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
    };
  };
}
