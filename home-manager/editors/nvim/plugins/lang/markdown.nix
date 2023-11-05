{ config
, pkgs
, ...
}: {
  home.packages = with pkgs;  [
    marksman
    ltex-ls
  ];

  programs.nixvim = {
    extraConfigLua =
      ''
                require'lspconfig'.marksman.setup{}
        				require'lspconfig'.ltex.setup{
                	cmd = { "ltex-ls" },
                	filetypes = { "markdown", "text" },
                	flags = { debounce_text_changes = 300 },
        				}
      '';

    plugins.treesitter = {
      grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
        markdown
        markdown_inline
      ];
    };
  };
}
