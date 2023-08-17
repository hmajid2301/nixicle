{ config, pkgs, ... }: {
  programs.nixvim.plugins = {
    treesitter = {
      enable = true;
      nixvimInjections = true;

      folding = true;
      indent = true;

      incrementalSelection = {
        enable = true;
      };

      grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
        c
        bash
        fish

        markdown
        markdown_inline

        vim
        vimdoc

        yaml
        json
        toml
      ];
    };

    treesitter-playground.enable = true;

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

