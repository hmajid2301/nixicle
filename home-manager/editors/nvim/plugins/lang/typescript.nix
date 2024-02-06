{
  pkgs,
  config,
  ...
}: {
  programs.nixvim = {
    plugins = {
      conform-nvim = {
        formattersByFt = {
          typescript = ["prettierd"];
          javascript = ["prettierd"];
        };

        formatters = {
          prettierd = {
            command = "${pkgs.prettierd}/bin/prettierd";
          };
        };
      };

      lint = {
        lintersByFt = {
          typescript = ["eslint_d"];
          javascript = ["eslint_d"];
        };
        linters = {
          eslint_d = {
            cmd = "${pkgs.eslint_d}/bin/eslint_d";
          };
        };
      };

      lsp.servers.tsserver = {
        enable = true;
      };

      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          typescript
          javascript
        ];
      };
    };
  };
}
