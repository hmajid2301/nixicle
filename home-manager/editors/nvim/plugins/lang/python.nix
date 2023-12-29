{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [
    pyright
  ];

  programs.nixvim = {
    extraConfigLua = ''
      require("lspconfig")["pyright"].setup({})
    '';

    plugins = {
      dap.extensions.dap-python.enable = true;

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
