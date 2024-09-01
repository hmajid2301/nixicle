{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    plugins = {
      conform-nvim = {
        settings = {
          formatters_by_ft = {
            css = ["prettierd"];
          };

          formatters = {
            prettierd = {
              command = "${pkgs.prettierd}/bin/prettierd";
            };
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
    };
  };
}
