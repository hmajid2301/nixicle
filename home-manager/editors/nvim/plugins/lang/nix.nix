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

      conform-nvim = {
        formattersByFt = {
          nix = [ "nixpkgs_fmt" ];
        };
      };

      lint = {
        # lintersByFt = {
        #   nix = [ "deadnix" ];
        # };
        # linters = {
        #   deadnix = {
        #     cmd = "${pkgs.deadnix}/bin/deadnix";
        #   };
        # };
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

    extraConfigLua = ''
      require'lspconfig'.nixd.setup{}
    '';
  };
}
