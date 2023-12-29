{
  pkgs,
  config,
  ...
}: {
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
      neorg = {
        enable = true;
        lazyLoading = true;
        modules = {
          "core.defaults" = {
            __empty = null;
          };
          "core.dirman".config = {
            workspaces = {
              notes = "~/notes";
            };
            default_workspace = "notes";
          };
          "core.integrations.telescope" = {
            __empty = null;
          };
          "core.concealer".__empty = null;
          "core.completion".config.engine = "nvim-cmp";
        };
      };

      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          norg
        ];
      };
    };
  };
}
