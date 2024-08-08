{
  pkgs,
  config,
  ...
}: let
  buildFlags = "-tags=unit,integration,e2e,bdd";
in {
  xdg.configFile."nvim/queries/go/injections.scm".text = builtins.readFile ./lua/go/injections.scm;

  home.packages = with pkgs; [delve];

  programs.nixvim = {
    files = {
      "ftplugin/templ.lua" = {
        opts = {
          expandtab = true;
          shiftwidth = 4;
          tabstop = 4;
        };
      };

      "ftplugin/go.lua" = {
        opts = {
          expandtab = true;
          shiftwidth = 4;
          tabstop = 4;
        };
      };
    };

    extraPlugins = with pkgs.vimPlugins; [
      neotest-golang
    ];

    plugins = {
      dap.extensions.dap-go = {
        enable = true;
        delve = {
          port = "38697";
          path = "dlv";
          inherit buildFlags;
        };
        dapConfigurations = [
          {
            type = "go";
            name = "Attach remote";
            mode = "remote";
            request = "attach";
          }
        ];
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
              "gitlab.com/hmajid2301"
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

      neotest = {
        settings = {
          adapters = [
            # lua
            ''
              require("neotest-golang")({
                go_test_args = {
                  "-v",
                  "-race",
                  "-count=1",
                  "-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out",
                },
                dap_go_enabled = true
              })
            ''
          ];
        };
      };

      lsp.servers = {
        templ = {
          enable = true;
        };

        gopls = {
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
      };

      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          templ
          go
          gomod
          gosum
          gowork
        ];
      };
    };
  };
}
