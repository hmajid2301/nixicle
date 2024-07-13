{
  pkgs,
  config,
  ...
}: let
  home = config.home.homeDirectory;
in {
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

      # lsp.servers.nil-ls = {
      #   enable = true;
      # };
      #
      lsp.servers.nixd = {
        enable = true;
        extraOptions.settings = {
          nixd = {
            nixpkgs = {
              expr = "import <nixpkgs> { }";
            };
            options = {
              nixos = {
                expr = ''(builtins.getFlake "${home}/dotfiles").nixosConfigurations.workstation.options'';
              };
              home_manager = {
                expr = ''(builtins.getFlake "${home}/dotfiles").homeConfigurations."haseeb@workstation".options'';
              };
              flake_parts = {
                expr = ''let flake = builtins.getFlake ("${home}/dotfiles"); in flake.debug.options // flake.currentSystem.options'';
              };
            };
          };
        };
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
