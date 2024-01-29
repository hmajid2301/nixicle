{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    plugins = {
      conform-nvim = {
        formattersByFt = {
          sql = ["sql_formatter"];
        };

        formatters = {
          sql_formatter = {
            command = "${pkgs.nodePackages_latest.sql-formatter}/bin/sql-formatter";
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
