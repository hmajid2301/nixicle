{pkgs, ...}: {
  programs.nixvim = {
    plugins.lsp.servers = {
      sqlls = {
        enable = true;
        package = pkgs.nixicle.sql-language-server;
        settings = {
          sqlLanguageServer = {
            connections = [
              {
                name = "postgres";
                adapter = "postgres";
                host = "localhost";
                port = 5432;
                user = "postgres";
                password = "postgres";
                database = "postgres";
              }
            ];
          };
        };
      };
      sqls = {
        enable = true;
        settings = {
          sqls = {
            connections = [
              {
                driver = "postgresql";
                dataSourceName = "host=127.0.0.1 port=5432 user=postgres password=postgres dbname=postgres sslmode=disable";
              }
            ];
          };
        };
      };
    };

    extraPlugins = with pkgs.vimPlugins; [
      nvim-dbee
    ];

    extraConfigLua = ''
      require("dbee").setup()
    '';
  };
}
