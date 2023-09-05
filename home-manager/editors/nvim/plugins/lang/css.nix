{ config, ... }: {
  programs.nixvim = {
    treesitter = {
      grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
        css
      ];
    };
  };
}
