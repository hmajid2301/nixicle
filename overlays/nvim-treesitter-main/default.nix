inputs: final: prev: {
  vimPlugins = prev.vimPlugins // {
    # Use the main branch nvim-treesitter with all grammars
    nvim-treesitter = prev.vimPlugins.nvim-treesitter.withAllGrammars;
    # Ensure textobjects uses the correct treesitter version
    nvim-treesitter-textobjects = prev.vimPlugins.nvim-treesitter-textobjects.overrideAttrs (old: {
      dependencies = with prev.vimPlugins; [ nvim-treesitter ];
    });
  };
}