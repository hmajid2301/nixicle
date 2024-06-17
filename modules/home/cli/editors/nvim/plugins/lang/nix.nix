{
  pkgs,
  config,
  ...
}: {
  programs.nixvim = {
    files = {
      "ftplugin/nix.lua" = {
        opts = {
          expandtab = true;
          shiftwidth = 2;
          tabstop = 2;
        };
      };
    };

    plugins = {
      nix.enable = true;
      hmts.enable = true;
      nix-develop.enable = true;

      conform-nvim = {
        formattersByFt = {
          nix = ["alejandra"];
        };
        formatters = {
          alejandra = {
            command = "${pkgs.alejandra}/bin/alejandra";
          };
        };
      };

      lint = {
        lintersByFt = {
          nix = ["statix"];
        };
        linters = {
          statix = {
            cmd = "${pkgs.statix}/bin/statix";
          };
        };
      };

      lsp.servers.nil-ls = {
        enable = true;
      };

      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          nix
        ];
      };
    };

    extraConfigVim = ''
      au BufRead,BufNewFile flake.lock setf json
    '';
  };
}
