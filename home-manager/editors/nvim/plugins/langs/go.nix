{config, ...}: {
  programs.nixvim = {
    plugins = {
      dap.extensions.dap-go.enable = true;
      lsp.servers.gopls.enable = true;
      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          go
          gomod
          gosum
          gowork
        ];
      };
    };
  };
}
