{
  pkgs,
  config,
  ...
}: let
  buildFlags = "-tags=unit,integration,e2e,bdd,dind";
in {
  xdg.configFile."nvim/queries/go/injections.scm".text = builtins.readFile ./lua/go/injections.scm;
  xdg.configFile."nvim/queries/templ/injections.scm".text = builtins.readFile ./lua/html/injections.scm;

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
        settings = {
          formatters_by_ft = {
            # go = ["goimports" "golines"];
            go = ["goimports"];
          };

          formatters = {
            # TODO: auto toggle
            # golines = {
            #   command = "${pkgs.golines}/bin/golines";
            #   args = [
            #     "-m"
            #     "120"
            #   ];
            # };
            goimports = {
              command = "${pkgs.gotools}/bin/goimports";
              args = [
                "-local"
                "gitlab.com/hmajid2301,git.curve.tools,go.curve.tools"
              ];
            };
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
        adapters.golang = {
          enable = true;
          settings = {
            dap_go_enabled = true;
            go_list_args = [buildFlags];
            go_test_args = [buildFlags];
            dap_go_opts = {
              delve = {
                build_flags = [buildFlags];
              };
            };
          };
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
    };
  };
}
