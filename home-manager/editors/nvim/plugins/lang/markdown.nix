{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    extraPlugins = with pkgs; [
      marksman
    ];

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
