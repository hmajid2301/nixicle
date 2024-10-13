{
  pkgs,
  config,
  ...
}: {
  programs.nixvim = {
    files = {
      "ftplugin/jinja.lua" = {
        opts = {
          expandtab = true;
          shiftwidth = 4;
          tabstop = 4;
        };
      };

      "ftplugin/go.lua" = {
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
            jinja = ["djlint"];
          };

          formatters = {
            djlint = {
              command = "${pkgs.djlint}/bin/djlint";
            };
          };
        };
      };

      # lsp.servers = {
      #   jinja_lsp = {
      #     enable = true;
      #   };
      # };
    };
  };
}
