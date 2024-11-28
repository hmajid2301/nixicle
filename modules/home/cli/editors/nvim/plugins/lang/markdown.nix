{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    files = {
      "ftplugin/markdown.lua" = {
        extraConfigLua = ''
          vim.opt.formatoptions:append('t')
        '';
        localOpts = {
          textwidth = 120;
        };
        opts = {
          conceallevel = 1;
          expandtab = true;
          shiftwidth = 2;
          tabstop = 2;
          linebreak = true;
          # textwidth = 120;
          wrap = true;
          wrapmargin = 0;
        };
      };
    };

    plugins = {
      clipboard-image = {
        enable = true;
        clipboardPackage = pkgs.wl-clipboard;
      };

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
    };
  };
}
