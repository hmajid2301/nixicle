{ pkgs
, config
, ...
}: {
  home.packages = with pkgs; [
    nixd
  ];

  programs.nixvim = {
    plugins = {
      nix.enable = true;
      hmts.enable = true;
      nix-develop.enable = true;

      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          nix
        ];
      };
    };

    extraConfigVim = ''
      au BufRead,BufNewFile flake.lock setf json
    '';

    extraConfigLua = ''
      require'lspconfig'.nixd.setup{}
      require("conform").setup({
      	formatters_by_ft = {
      		nix = { "nixpkgs_fmt " },
      	},
      	formatters = {
      		nixpkgs_fmt  = {
      			command = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt",
      		},
      	},
      })

      require('lint').linters_by_ft = {
      	nix = {'deadnix'}
      }
      require('lint').linters.deadnix = {
      	cmd = "${pkgs.deadnix}/bin/deadnix",
      }
    '';
  };
}
