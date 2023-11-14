{ pkgs
, config
, ...
}: {
  home.packages = with pkgs; [
    golangci-lint-langserver
    delve
    gopls
  ];

  programs.nixvim = {
    keymaps = [
      {
        action = "<cmd> lua require('dap-go').debug_test()<CR>";
        key = "<leader>td";
        options = {
          desc = "Debug Nearest (Go)";
        };
        mode = [
          "n"
        ];
      }
    ];

    extraPlugins = with pkgs.vimPlugins; [
      go-nvim
    ];

    extraConfigLua = ''
      require("go").setup({
      	icons = false,
      })

      require('lint').linters_by_ft = {
      	go = {'golangcilint'}
      }

      require("conform").setup({
      	formatters_by_ft = {
      		go = { "goimports" },
      	},
      	formatters = {
      		goimports = {
      			command = "${pkgs.gotools}/bin/goimports",
      		},
      	},
      })

      require('lint').linters.golangcilint = {
      	cmd = "${pkgs.golangci-lint}/bin/golangci-lint",
      }
    '';

    plugins = {
      dap.extensions.dap-go.enable = true;

      lsp.servers.gopls = {
        enable = true;
        extraOptions.settings = {
          gopls = {
            buildFlags = [ "-tags=unit,integration,e2e" ];
            staticcheck = true;
            directoryFilters = [ "-.git" "-.vscode" "-.idea" "-.vscode-test" "-node_modules" ];
            semanticTokens = true;
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

