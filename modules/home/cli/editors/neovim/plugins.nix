{ pkgs, categories, ... }:
{
  startupPlugins = {
    debug = with pkgs.vimPlugins; [ nvim-nio ];
    general = with pkgs.vimPlugins; {
      always = [
        lze
        lzextras
        vim-repeat
        plenary-nvim
      ];
      extra = [
        oil-nvim
        SchemaStore-nvim
        nvim-web-devicons
        auto-session
      ];
    };
    themer =
      with pkgs.vimPlugins;
      (builtins.getAttr (categories.colorscheme or "catppuccin") {
        "catppuccin" = catppuccin-nvim;
        "catppuccin-mocha" = catppuccin-nvim;
      });
  };
  optionalPlugins = {
    debug = with pkgs.vimPlugins; [
      nvim-dap
      pkgs.neovimPlugins.nvim-dap-view
      nvim-dap-go
      debugmaster-nvim
    ];
    test = with pkgs.vimPlugins; [
      # Use latest neotest with PR #548 fix
      pkgs.neovimPlugins.neotest
      # neotest-golang
      pkgs.neovimPlugins.neotest-golang
      nvim-nio
      nvim-coverage
      vim-dotenv
    ];
    lint = with pkgs.vimPlugins; [ nvim-lint ];
    format = with pkgs.vimPlugins; [ conform-nvim ];
    neonixdev = with pkgs.vimPlugins; [ lazydev-nvim ];
    general = {
      ai = with pkgs.vimPlugins; [
        sidekick-nvim
      ];
      cmp = with pkgs.vimPlugins; [
        blink-cmp
        blink-compat
        blink-ripgrep-nvim
        blink-cmp-avante
        luasnip
        friendly-snippets
        lspkind-nvim
        (pkgs.neovimPlugins.cmp-dbee.overrideAttrs {
          nvimSkipModule = [
            "cmp-dbee.connection"
            "cmp-dbee.source"
          ];
        })
        pkgs.neovimPlugins.cmp-go-deep
        sqlite-lua
      ];
      treesitter = with pkgs.vimPlugins; [
        nvim-treesitter-textobjects
        # Using nvim-treesitter main branch via overlay for neotest-golang v2+ compatibility
        # See: https://fredrikaverpil.github.io/neotest-golang/install/
        # Overlay from: https://github.com/iofq/nvim-treesitter-main
        nvim-treesitter.withAllGrammars
      ];
      telescope = with pkgs.vimPlugins; [
        telescope-fzf-native-nvim
        telescope-media-files-nvim
        telescope-ui-select-nvim
        telescope-nvim
      ];
      always = with pkgs.vimPlugins; [ nvim-lspconfig ];
      git = with pkgs.vimPlugins; [
        gitsigns-nvim
        diffview-nvim
        advanced-git-search-nvim
        neogit
        git-worktree-nvim
        pkgs.neovimPlugins.webify-nvim
      ];
      diagnostics = with pkgs.vimPlugins; [ trouble-nvim ];
      editor = with pkgs.vimPlugins; [
        mini-nvim
        fyler-nvim
        refactoring-nvim
        arrow-nvim
        vim-illuminate
        nvim-navic
        todo-comments-nvim
        grug-far-nvim
        smart-splits-nvim
        yanky-nvim
        inc-rename-nvim
        snacks-nvim
        quicker-nvim
        pkgs.neovimPlugins.gx-nvim
        pkgs.neovimPlugins.templ-goto-definition
        pkgs.neovimPlugins.tiny-code-actions
        pkgs.neovimPlugins.inline-edit
      ];
      extra = with pkgs.vimPlugins; [
        fidget-nvim
        # lualine-lsp-progress
        comment-nvim
        undotree
        nvim-dbee
      ];
      notes = with pkgs.vimPlugins; [
        markview-nvim
      ];
      ui = with pkgs.vimPlugins; [
        indent-blankline-nvim
        lualine-nvim
        dropbar-nvim
        helpview-nvim
        nvim-highlight-colors
      ];
    };
  };
  # shared libraries to be added to LD_LIBRARY_PATH
  # variable available to nvim runtime
  sharedLibraries = {
    general = with pkgs; [
      # libgit2
    ];
  };
  environmentVariables = {
    test = {
      CATTESTVAR = "It worked!";
    };
  };
  extraWrapperArgs = {
    test = [ ''--set CATTESTVAR2 "It worked again!"'' ];
  };
  # lists of the functions you would have passed to
  # python.withPackages or lua.withPackages

  # get the path to this python environment
  # in your lua config via
  # vim.g.python3_host_prog
  # or run from nvim terminal via :!<packagename>-python3
  python3.libraries = {
    test = _: [ ];
  };
  # populates $LUA_PATH and $LUA_CPATH
  extraLuaPackages = {
    test = [ (_: [ ]) ];
  };
}
