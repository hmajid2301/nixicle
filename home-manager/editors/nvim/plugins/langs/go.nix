{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [
    golangci-lint-langserver
  ];

  programs.nixvim = {
    maps = {
      normal = {
        "<leader>td" = {
          action = "<cmd>lua require('dap-go').debug_test()<CR>";
          desc = "Debug Nearest (Go)";
        };
      };
    };

    extraPlugins = with pkgs.vimPlugins; [
      neotest-go
      go-nvim
    ];

    extraConfigLua =
      # lua
      ''
        local neotest = require('neotest')
        neotest.setup {
          adapters = {
            require('neotest-go') {
            },
          },
        }
      '';

    plugins = {
      dap.extensions.dap-go.enable = true;
      lsp.servers.gopls = {
        enable = true;
      };

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
