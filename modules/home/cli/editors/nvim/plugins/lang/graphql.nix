{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    files = {
      "ftplugin/graphql.lua" = {
        opts = {
          expandtab = true;
          shiftwidth = 2;
          tabstop = 2;
        };
      };
    };

    plugins = {
      lsp.servers = {
        graphql = {
          enable = true;
        };
      };
    };
  };
}
