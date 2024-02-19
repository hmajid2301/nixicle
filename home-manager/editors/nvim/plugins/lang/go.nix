{
  pkgs,
  config,
  ...
}: let
  buildFlags = "-tags=unit,integration,e2e,bdd";
in {
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

    plugins = {
      dap.extensions.dap-go = {
        enable = true;
        delve = {
          path = "${pkgs.delve}/bin/dlv";
          inherit buildFlags;
        };
      };

      conform-nvim = {
        formattersByFt = {
          go = ["goimports"];
        };

        formatters = {
          goimports = {
            command = "${pkgs.gotools}/bin/goimports";
            args = [
              "-local"
              "gitlab.com/majiy00,gitlab.com/hmajid2301"
            ];
          };
        };
      };

      lint = {
        lintersByFt = {
          go = ["golangcilint"];
        };
        linters = {
          golangcilint = {
            cmd = "${pkgs.golangci-lint}/bin/golangci-lint";
          };
        };
      };

      lsp.servers.gopls = {
        enable = true;

        extraOptions.settings = {
          gopls = {
            buildFlags = [buildFlags];
            staticcheck = true;
            directoryFilters = ["-.git" "-.vscode" "-.idea" "-.vscode-test" "-node_modules"];
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
              assignVariableTypes = false;
              compositeLiteralFields = false;
              compositeLiteralTypes = false;
              constantValues = true;
              functionTypeParameters = true;
              parameterNames = true;
              rangeVariableTypes = false;
            };
            analyses = {
              assign = true;
              bools = true;
              defers = true;
              deprecated = true;
              fieldalignment = true;
              tests = true;
              nilness = true;
              httpresponse = true;
              unmarshal = true;
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
