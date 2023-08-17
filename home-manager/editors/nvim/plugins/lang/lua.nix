{config, ...}: {
  programs.nixvim = {
    plugins.lsp.servers.lua-ls.enable = true;

    plugins.treesitter = {
      grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
        lua
        luadoc
        luap
      ];
    };
  };
}
