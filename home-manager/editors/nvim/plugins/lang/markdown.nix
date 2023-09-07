{ config
, pkgs
, ...
}: {
  home.packages = with pkgs;  [
    marksman
  ];

  programs.nixvim = {
    extraConfigLua =
      # lua
      ''
        require'lspconfig'.marksman.setup{}
      '';

    plugins.treesitter = {
      grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
        markdown
        markdown_inline
      ];
    };
  };
}
