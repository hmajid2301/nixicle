{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    plugins.lsp.servers.taplo = {
      enable = true;
    };
  };
}
