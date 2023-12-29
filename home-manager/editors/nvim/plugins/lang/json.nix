{config, ...}: {
  programs.nixvim = {
    plugins.lsp.servers.jsonls = {
      enable = true;
    };

    plugins.treesitter = {
      grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
        json
      ];
    };
  };
}
