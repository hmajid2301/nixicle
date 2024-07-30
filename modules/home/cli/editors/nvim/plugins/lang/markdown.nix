{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    files = {
      "ftplugin/markdown.lua" = {
        opts = {
          conceallevel = 1;
          expandtab = true;
          shiftwidth = 2;
          tabstop = 2;
        };
      };
    };

    plugins = {
      image = {
        enable = true;
        integrations.markdown = {
          clearInInsertMode = true;
          onlyRenderImageAtCursor = true;
        };
      };

      lsp.servers = {
        marksman = {
          enable = true;
        };

        ltex = {
          enable = true;
          filetypes = [
            "markdown"
            "text"
          ];

          settings = {
            completionEnabled = true;
          };

          extraOptions = {
            checkFrequency = "save";
            language = "en-GB";
          };
        };
      };

      lint = {
        lintersByFt = {
          md = ["markdownlint-cli2"];
        };
        linters = {
          markdownlint-cli2 = {
            cmd = "${pkgs.markdownlint-cli2}/bin/markdownlint-cli2";
          };
        };
      };

      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          markdown
          markdown_inline
        ];
      };
    };
  };
}
