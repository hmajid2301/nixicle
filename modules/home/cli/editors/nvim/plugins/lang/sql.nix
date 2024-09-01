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
        settings = {
          formatters_by_ft = {
            sql = ["sqlfluff"];
          };

          formatters = {
            sqlfluff = {
              command = "${pkgs.sqlfluff}/bin/sqlfluff";
            };
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
    };
  };
}
