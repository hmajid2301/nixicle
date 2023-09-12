{ pkgs
, config
, ...
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
        require("go").setup()

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

        extraOptions.settings = {
          gopls = {
            gofumpt = true;
            codelenses = {
              gc_details = false;
              generate = true;
              regenerate_cgo = true;
              run_govulncheck = true;
              test = true;
              tidy = true;
              upgrade_dependency = true;
              vendor = true;
            };
            hints = {
              assignVariableTypes = true;
              compositeLiteralFields = true;
              compositeLiteralTypes = true;
              constantValues = true;
              functionTypeParameters = true;
              parameterNames = true;
              rangeVariableTypes = true;
            };
            analyses = {
              fieldalignment = true;
              nilness = true;
              unusedparams = true;
              unusedwrite = true;
              useany = true;
            };
            usePlaceholders = true;
            completeUnimported = true;
            staticcheck = true;
            directoryFilters = [ "-.git" "-.vscode" "-.idea" "-.vscode-test" "-node_modules" ];
            semanticTokens = true;
          };
        };
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
