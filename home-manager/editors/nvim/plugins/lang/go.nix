{ pkgs
, config
, ...
}: {
  home.packages = with pkgs; [
    golangci-lint-langserver
    gopls
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
      go-nvim
    ];

    extraConfigLua = ''
      require("go").setup({
      	icons = false;
      })

      local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

      require("lspconfig")["gopls"].setup({
      		capabilities = capabilities,
      		settings = {
      			gopls = {
      				gofumpt = true,
      				buildFlags = { "-tags=integration" },
      				codelenses = {
      					gc_details = false,
      					generate = true,
      					regenerate_cgo = true,
      					run_govulncheck = true,
      					test = true,
      					tidy = true,
      					upgrade_dependency = true,
      					vendor = true,
      				},
      				hints = {
      					assignVariableTypes = true,
      					compositeLiteralFields = true,
      					compositeLiteralTypes = true,
      					constantValues = true,
      					functionTypeParameters = true,
      					parameterNames = true,
      					rangeVariableTypes = true,
      				},
      				analyses = {
      					fieldalignment = true,
      					nilness = true,
      					unusedparams = true,
      					unusedwrite = true,
      					useany = true,
      				},
      				usePlaceholders = true,
      				completeUnimported = true,
      				staticcheck = true,
      				directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
      				semanticTokens = true,
      			},
      	 },
      })
    '';

    plugins = {
      dap.extensions.dap-go.enable = true;
      # TODO: workout how to get gopls to work in nixvim
      # lsp.servers.gopls = {
      #   enable = true;
      #   extraOptions.settings = {
      #     gopls = {
      #       buildFlags = [ "-tags=integration" ];
      #       gofumpt = true;
      #       codelenses = {
      #         gc_details = false;
      #         generate = true;
      #         regenerate_cgo = true;
      #         run_govulncheck = true;
      #         test = true;
      #         tidy = true;
      #         upgrade_dependency = true;
      #         vendor = true;
      #       };
      #       hints = {
      #         assignVariableTypes = true;
      #         compositeLiteralFields = true;
      #         compositeLiteralTypes = true;
      #         constantValues = true;
      #         functionTypeParameters = true;
      #         parameterNames = true;
      #         rangeVariableTypes = true;
      #       };
      #       analyses = {
      #         fieldalignment = true;
      #         nilness = true;
      #         unusedparams = true;
      #         unusedwrite = true;
      #         useany = true;
      #       };
      #       usePlaceholders = false;
      #       completeUnimported = true;
      #       staticcheck = true;
      #       directoryFilters = [ "-.git" "-.vscode" "-.idea" "-.vscode-test" "-node_modules" ];
      #       semanticTokens = true;
      #     };
      #   };
      # };

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
