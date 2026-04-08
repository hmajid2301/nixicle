# All plugin and LSP/tool declarations, mapped from old nixCats categories.
# Spec names match the for_cat = "name" references in lua config.
{
  config,
  lib,
  pkgs,
  inputs,
  # Passed from homeManager context via _module.args
  stylixColors ? { },
  ...
}:
{
  # Non-boolean info values exposed via nixInfo(nil, "info", "key") or nixInfo(nil, "key")
  config.info = {
    colorscheme = "catppuccin";
    lspDebugMode = false;
    colors = stylixColors;
    nixdExtras = {
      # nixd needs an importable nix expression string
      nixpkgs = "import ${inputs.nixpkgs} {}";
    };
  };

  # ── Foundation plugins (always loaded, non-lazy) ────────────────────────────
  config.specs.general = {
    data = with pkgs.vimPlugins; [
      lze
      lzextras
      vim-repeat
      plenary-nvim
      oil-nvim
      SchemaStore-nvim
      nvim-web-devicons
      auto-session
    ];
    postpkgs = with pkgs; [
      universal-ctags
      ripgrep
      fd
      stdenv.cc.cc
    ];
  };

  # ── Colorscheme ─────────────────────────────────────────────────────────────
  config.specs.colorscheme = {
    lazy = true;
    data = pkgs.vimPlugins.catppuccin-nvim;
  };

  # ── LSP core (nvim-lspconfig) ────────────────────────────────────────────────
  # for_cat = "lsp-core" in lua
  config.specs.lsp-core = {
    lazy = true;
    data = with pkgs.vimPlugins; [ nvim-lspconfig ];
  };

  # ── Nix dev extras (lazydev) ─────────────────────────────────────────────────
  config.specs.neonixdev = {
    lazy = true;
    data = with pkgs.vimPlugins; [ lazydev-nvim ];
    postpkgs = with pkgs; [
      # lua_ls is also used for neonixdev
    ];
  };

  # ── Completion ───────────────────────────────────────────────────────────────
  config.specs.cmp = {
    lazy = true;
    data = with pkgs.vimPlugins; [
      blink-cmp
      blink-compat
      blink-ripgrep-nvim
      blink-cmp-avante
      luasnip
      friendly-snippets
      lspkind-nvim
      (config.nvim-lib.neovimPlugins.cmp-dbee.overrideAttrs {
        nvimSkipModule = [
          "cmp-dbee.connection"
          "cmp-dbee.source"
        ];
      })
      config.nvim-lib.neovimPlugins.cmp-go-deep
      sqlite-lua
    ];
  };

  # ── Tree-sitter ──────────────────────────────────────────────────────────────
  config.specs.treesitter = {
    lazy = true;
    data = with pkgs.vimPlugins; [
      nvim-treesitter.withAllGrammars
    ];
  };

  # ── Telescope ────────────────────────────────────────────────────────────────
  config.specs.telescope = {
    lazy = true;
    data = with pkgs.vimPlugins; [
      telescope-fzf-native-nvim
      telescope-media-files-nvim
      telescope-ui-select-nvim
      telescope-nvim
    ];
  };

  # ── Git ──────────────────────────────────────────────────────────────────────
  config.specs.git = {
    lazy = true;
    data = with pkgs.vimPlugins; [
      gitsigns-nvim
      diffview-nvim
      advanced-git-search-nvim
      neogit
      git-worktree-nvim
      config.nvim-lib.neovimPlugins.webify-nvim
    ];
  };

  # ── Debug ────────────────────────────────────────────────────────────────────
  config.specs.debug = {
    lazy = true;
    data = with pkgs.vimPlugins; [
      nvim-nio
      nvim-dap
      config.nvim-lib.neovimPlugins.nvim-dap-view
      nvim-dap-go
      debugmaster-nvim
    ];
  };

  # ── Test ─────────────────────────────────────────────────────────────────────
  config.specs.test = {
    lazy = true;
    data = with pkgs.vimPlugins; [
      neotest
      neotest-golang
      nvim-nio
      nvim-coverage
      vim-dotenv
    ];
  };

  # ── Lint ─────────────────────────────────────────────────────────────────────
  config.specs.lint = {
    lazy = true;
    data = with pkgs.vimPlugins; [ nvim-lint ];
  };

  # ── Format ───────────────────────────────────────────────────────────────────
  config.specs.format = {
    lazy = true;
    data = with pkgs.vimPlugins; [ conform-nvim ];
  };

  # ── AI ───────────────────────────────────────────────────────────────────────
  config.specs.ai = {
    lazy = true;
    data = with pkgs.vimPlugins; [ sidekick-nvim ];
  };

  # ── Editor plugins ───────────────────────────────────────────────────────────
  config.specs.editor = {
    lazy = true;
    data = with pkgs.vimPlugins; [
      mini-nvim
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
      flash-nvim
      zen-mode-nvim
      config.nvim-lib.neovimPlugins.gx-nvim
      config.nvim-lib.neovimPlugins.templ-goto-definition
      config.nvim-lib.neovimPlugins.tiny-code-actions
      config.nvim-lib.neovimPlugins.inline-edit
      config.nvim-lib.neovimPlugins.warp-nvim
    ];
  };

  # ── Extra plugins ────────────────────────────────────────────────────────────
  config.specs.extra = {
    lazy = true;
    data = with pkgs.vimPlugins; [
      fidget-nvim
      comment-nvim
      nvim-dbee
    ];
  };

  # ── Notes ────────────────────────────────────────────────────────────────────
  config.specs.notes = {
    lazy = true;
    data = with pkgs.vimPlugins; [
      markview-nvim
      zk-nvim
      img-clip-nvim
    ];
  };

  # ── UI ───────────────────────────────────────────────────────────────────────
  config.specs.ui = {
    lazy = true;
    data = with pkgs.vimPlugins; [
      indent-blankline-nvim
      lualine-nvim
      dropbar-nvim
      helpview-nvim
      nvim-highlight-colors
    ];
  };

  # ── Diagnostics ──────────────────────────────────────────────────────────────
  config.specs.diagnostics = {
    lazy = true;
    data = with pkgs.vimPlugins; [ trouble-nvim ];
  };

  # ════════════════════════════════════════════════════════════════════════════
  # Language specs: data = null means no plugins, just tools in postpkgs
  # ════════════════════════════════════════════════════════════════════════════

  config.specs.go = {
    data = null;
    postpkgs = with pkgs; [
      go
      golangci-lint
      delve
      gopls
      go-tools
      gotools
      gotestsum
      inputs.templ.packages.${pkgs.stdenv.hostPlatform.system}.templ
    ];
  };

  config.specs.nix = {
    data = null;
    postpkgs = with pkgs; [
      nixd
      nixfmt
      statix
      nix-doc
    ];
  };

  config.specs.lua = {
    data = null;
    postpkgs = with pkgs; [
      stylua
      luajitPackages.luacheck
      lua-language-server
    ];
  };

  config.specs.python = {
    data = null;
    postpkgs = with pkgs; [
      isort
      black
      pyright
    ];
  };

  config.specs.css = {
    data = null;
    postpkgs = with pkgs; [
      stylelint
      prettierd
      rustywind
      tailwindcss-language-server
    ];
  };

  config.specs.docker = {
    data = null;
    postpkgs = with pkgs; [
      dockerfile-language-server-nodejs
      docker-compose-language-service
      hadolint
    ];
  };

  config.specs.html = {
    data = null;
    postpkgs = with pkgs; [
      htmlhint
      rubyPackages_3_4.htmlbeautifier
      htmx-lsp
      vscode-langservers-extracted
      svelte-language-server
    ];
  };

  config.specs.json = {
    data = null;
    postpkgs = with pkgs; [ vscode-langservers-extracted ];
  };

  config.specs.markdown = {
    data = null;
    postpkgs = with pkgs; [
      marksman
      markdownlint-cli2
      harper
    ];
  };

  config.specs.sql = {
    data = null;
    postpkgs = with pkgs; [
      sqls
      sqlfluff
    ];
  };

  config.specs.terraform = {
    data = null;
    postpkgs = with pkgs; [
      terraform
      terraform-lsp
      tflint
      tfsec
    ];
  };

  config.specs.toml = {
    data = null;
    postpkgs = with pkgs; [ taplo ];
  };

  config.specs.templ = {
    data = null;
    postpkgs = with pkgs; [ inputs.templ.packages.${pkgs.stdenv.hostPlatform.system}.templ ];
  };

  config.specs.typescript = {
    data = null;
    postpkgs = with pkgs; [
      typescript-language-server
      eslint
    ];
  };

  config.specs.yaml = {
    data = null;
    postpkgs = with pkgs; [
      yamlfmt
      yamllint
      yaml-language-server
    ];
  };
}
