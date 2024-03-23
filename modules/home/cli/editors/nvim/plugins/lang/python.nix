{
  pkgs,
  config,
  ...
}: {
  programs.nixvim = {
    plugins = {
      dap.extensions.dap-python.enable = true;

      neotest = {
        adapters.python = {
          enable = true;
        };
      };

      lsp.servers.pyright.enable = true;

      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          ninja
          python
          rst
        ];
      };
    };
  };
}
