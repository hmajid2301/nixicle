{config, ...}: {
  programs.nixvim = {
    files = {
      "ftplugin/yaml.lua" = {
        opts = {
          expandtab = false;
          shiftwidth = 2;
          tabstop = 2;
        };
      };
    };

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
