{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    plugins = {
      conform-nvim = {
        formattersByFt = {
          sql = ["sqlfluff"];
        };

        formatters = {
          sqlfluff = {
            command = "${pkgs.sqlfluff}/bin/sqlfluff";
          };
        };
      };

      lint = {
        lintersByFt = {
          sql = ["sqlfluff"];
        };
        linters = {
          sqlfluff = {
            cmd = "${pkgs.sqlfluff}/bin/sqlfluff";
          };
        };
      };

      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          sql
        ];
      };
    };
  };
}
