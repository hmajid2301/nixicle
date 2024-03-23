{config, ...}: {
  programs.nixvim = {
    plugins.lsp.servers.yamlls = {
      enable = true;
      extraOptions = {
        capabilities = {
          textDocument = {
            foldingRange = {
              dynamicRegistration = false;
              lineFoldingOnly = true;
            };
          };
        };
      };
    };

    plugins.treesitter = {
      grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
        yaml
      ];
    };
  };
}
