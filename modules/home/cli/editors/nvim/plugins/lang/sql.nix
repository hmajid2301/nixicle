{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    files = {
      "ftplugin/sql.lua" = {
        opts = {
          expandtab = true;
          shiftwidth = 4;
          tabstop = 4;
        };
      };
    };

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
