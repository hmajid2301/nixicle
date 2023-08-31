{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    tree-sitter
  ];

  programs.nixvim.plugins = {
    treesitter = {
      enable = true;
      nixvimInjections = true;
      indent = false;

      incrementalSelection = {
        enable = true;
      };

      grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
        c
        bash
        fish

        vim
        vimdoc

        json
        toml
      ];
    };

    # extraPlugins = with pkgs.vimPlugins; [
    #   nvim-treesitter-textobjects
    # ];

    # treesitter-rainbow.enable = true;
    # treesitter-refactor = {
    #   enable = true;
    #   highlightDefinitions.enable = true;
    # };
    #
    # treesitter-context = {
    #   enable = true;
    # };
  };
}
