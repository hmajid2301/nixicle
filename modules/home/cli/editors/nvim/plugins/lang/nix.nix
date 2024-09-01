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
        settings = {
          formatters_by_ft = {
            nix = ["alejandra"];
          };
          formatters = {
            alejandra = {
              command = "${pkgs.alejandra}/bin/alejandra";
            };
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
                expr = ''(builtins.getFlake "${home}/nixicle").nixosConfigurations.workstation.options'';
              };
              home_manager = {
                expr = ''(builtins.getFlake "${home}/nixicle").homeConfigurations."haseeb@workstation".options'';
              };
              flake_parts = {
                expr = ''let flake = builtins.getFlake ("${home}/nixicle"); in flake.debug.options // flake.currentSystem.options'';
              };
            };
          };
        };
      };
    };

    extraConfigVim = ''
      au BufRead,BufNewFile flake.lock setf json
    '';
  };
}
