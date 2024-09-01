{
  pkgs,
  config,
  ...
}: {
  programs.nixvim = {
    plugins = {
      dap.extensions.dap-python.enable = true;

      neotest = {
        adapters.python = {
          enable = true;
        };
      };

      lsp.servers.pyright.enable = true;
    };
  };
}
