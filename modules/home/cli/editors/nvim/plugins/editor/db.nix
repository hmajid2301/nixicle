{pkgs, ...}: {
  programs.nixvim = {
    plugins.lsp.servers = {
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
