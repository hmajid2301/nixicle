{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    plugins = {
      conform-nvim = {
        formattersByFt = {
          css = ["prettierd"];
        };

        formatters = {
          prettierd = {
            command = "${pkgs.prettierd}/bin/prettierd";
          };
        };
      };

      lint = {
        lintersByFt = {
          css = ["stylelint"];
        };
        linters = {
          stylelint = {
            cmd = "${pkgs.stylelint}/bin/stylelint";
          };
        };
      };

      lsp.servers.cssls = {
        enable = true;
      };

      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          css
        ];
      };
    };
  };
}
