{
  pkgs,
  config,
  ...
}: {
  programs.nixvim = {
    files = {
      "ftplugin/svelte.lua" = {
        opts = {
          expandtab = true;
          shiftwidth = 4;
          tabstop = 4;
        };
      };
    };

    plugins = {
      lsp.servers.svelte = {
        enable = true;
      };

      lsp.servers.tailwindcss = {
        enable = true;
        filetypes = ["svelte"];
      };

      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          svelte
        ];
      };
    };
  };
}
