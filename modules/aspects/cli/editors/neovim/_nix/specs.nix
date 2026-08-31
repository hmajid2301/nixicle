{
  config,
  pkgs,
  inputs,
  stylixColors ? { },
  ...
}:
{
  config = {
    info = {
      colorscheme = "catppuccin";
      lspDebugMode = false;
      colors = stylixColors;
      nixdExtras = {
        nixpkgs = "import ${inputs.nixpkgs} {}";
      };
    };

    specs = {
      general = {
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

      colorscheme = {
        data = pkgs.vimPlugins.catppuccin-nvim;
      };

      lsp-core = {
        lazy = true;
        data = with pkgs.vimPlugins; [ nvim-lspconfig ];
      };

      neonixdev = {
        lazy = true;
        data = with pkgs.vimPlugins; [ lazydev-nvim ];
        postpkgs = with pkgs; [
        ];
      };

      cmp = {
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

      treesitter = {
        lazy = true;
        data = with pkgs.vimPlugins; [
          nvim-treesitter.withAllGrammars
          nvim-treesitter-textobjects
        ];
      };

      telescope = {
        lazy = true;
        data = with pkgs.vimPlugins; [
          telescope-fzf-native-nvim
          telescope-media-files-nvim
          telescope-ui-select-nvim
          telescope-nvim
        ];
      };

      git = {
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

      debug = {
        lazy = true;
        data = with pkgs.vimPlugins; [
          nvim-nio
          nvim-dap
          config.nvim-lib.neovimPlugins.nvim-dap-view
          nvim-dap-go
          debugmaster-nvim
        ];
      };

      test = {
        lazy = true;
        data = with pkgs.vimPlugins; [
          neotest
          neotest-golang
          nvim-nio
          nvim-coverage
          vim-dotenv
        ];
      };

      lint = {
        lazy = true;
        data = with pkgs.vimPlugins; [ nvim-lint ];
      };

      format = {
        lazy = true;
        data = with pkgs.vimPlugins; [ conform-nvim ];
      };

      pi-nvim = {
        lazy = true;
        data = config.nvim-lib.neovimPlugins.pi-nvim;
      };

      editor = {
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
          herdr-splits-nvim
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

      extra = {
        lazy = true;
        data = with pkgs.vimPlugins; [
          fidget-nvim
          comment-nvim
          nvim-dbee
        ];
      };

      notes = {
        lazy = true;
        data = with pkgs.vimPlugins; [
          markview-nvim
          zk-nvim
          img-clip-nvim
        ];
      };

      ui = {
        lazy = true;
        data = with pkgs.vimPlugins; [
          indent-blankline-nvim
          lualine-nvim
          dropbar-nvim
          helpview-nvim
          nvim-highlight-colors
        ];
      };

      diagnostics = {
        lazy = true;
        data = with pkgs.vimPlugins; [ trouble-nvim ];
      };

      go = {
        data = null;
        postpkgs = with pkgs; [
          go
          golangci-lint
          delve
          gopls
          go-tools
          gotools
          gotestsum
          templ
        ];
      };

      nix = {
        data = null;
        postpkgs = with pkgs; [
          nixd
          nixfmt
          statix
          nix-doc
        ];
      };

      lua = {
        data = null;
        postpkgs = with pkgs; [
          stylua
          luajitPackages.luacheck
          lua-language-server
        ];
      };

      python = {
        data = null;
        postpkgs = with pkgs; [
          isort
          black
          pyright
        ];
      };

      css = {
        data = null;
        postpkgs = with pkgs; [
          stylelint
          prettierd
          rustywind
          tailwindcss-language-server
        ];
      };

      docker = {
        data = null;
        postpkgs = with pkgs; [
          dockerfile-language-server
          docker-compose-language-service
          hadolint
        ];
      };

      html = {
        data = null;
        postpkgs = with pkgs; [
          htmlhint
          rubyPackages_3_4.htmlbeautifier
          htmx-lsp
          vscode-langservers-extracted
          svelte-language-server
        ];
      };

      json = {
        data = null;
        postpkgs = with pkgs; [ vscode-langservers-extracted ];
      };

      markdown = {
        data = null;
        postpkgs = with pkgs; [
          marksman
          markdownlint-cli2
          harper
        ];
      };

      sql = {
        data = null;
        postpkgs = with pkgs; [
          sqls
          sqlfluff
        ];
      };

      terraform = {
        data = null;
        postpkgs = with pkgs; [
          terraform
          terraform-lsp
          tflint
          tfsec
        ];
      };

      toml = {
        data = null;
        postpkgs = with pkgs; [ taplo ];
      };

      templ = {
        data = null;
        postpkgs = with pkgs; [ templ ];
      };

      typescript = {
        data = null;
        postpkgs = with pkgs; [
          typescript-language-server
          eslint
        ];
      };

      yaml = {
        data = null;
        postpkgs = with pkgs; [
          yamlfmt
          yamllint
          yaml-language-server
        ];
      };
    };
  };
}
