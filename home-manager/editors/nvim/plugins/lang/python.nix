{ pkgs
, config
, ...
}: {
  home.packages = with pkgs; [
    pyright
  ];

  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      neotest-python
    ];

    extraConfigLua = ''
      require('neotest').setup {
      	adapters = {
      		require('neotest-python') {
      		},
      	},
      }

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
