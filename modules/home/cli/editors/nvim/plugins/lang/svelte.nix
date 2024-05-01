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
      # conform-nvim = {
      #   formattersByFt = {
      #     go = ["goimports"];
      #   };
      #
      #   formatters = {
      #     goimports = {
      #       command = "${pkgs.gotools}/bin/goimports";
      #       args = [
      #         "-local"
      #         "gitlab.com/majiy00,gitlab.com/hmajid2301"
      #       ];
      #     };
      #   };
      # };
      #
      # lint = {
      #   lintersByFt = {
      #     go = ["golangcilint"];
      #   };
      #   linters = {
      #     golangcilint = {
      #       cmd = "${pkgs.golangci-lint}/bin/golangci-lint";
      #     };
      #   };
      # };

      lsp.servers.svelte = {
        enable = true;
      };

      lsp.servers.tailwindcss = {
        enable = true;
      };

      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          svelte
        ];
      };
    };
  };
}
