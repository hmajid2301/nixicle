{config, ...}: {
  programs.nixvim = {
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
    };

    plugins.treesitter = {
      grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
        markdown
        markdown_inline
      ];
    };
  };
}
