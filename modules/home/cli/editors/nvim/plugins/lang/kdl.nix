{config, ...}: {
  programs.nixvim = {
    plugins = {
      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          kdl
        ];
      };
    };
  };
}
