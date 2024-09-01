{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    plugins.lsp.servers.jsonls = {
      enable = true;
    };
  };
}
