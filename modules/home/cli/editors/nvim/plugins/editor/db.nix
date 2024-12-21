{pkgs, ...}: {
  programs.nixvim = {
    plugins.lsp.servers = {
      sqls = {
        enable = false;
        settings = {
          sqls = {
            connections = [
              {
                driver = "postgresql";
                dataSourceName = "host=127.0.0.1 port=5432 user=postgres password=postgres dbname=postgres sslmode=disable";
              }
            ];
            onAttach = {
              function = ''
                client.server_capabilities.documentFormattingProvider = false
                client.server_capabilities.documentRangeFormattingProvider = false
                require('sqls').on_attach(client, bufnr)
              '';
            };
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
