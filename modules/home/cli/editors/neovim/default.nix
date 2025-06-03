{
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (inputs.nixCats) utils;
in
{
  imports = [ inputs.nixCats.homeModule ];

  # TODO: enable true like every other package
  config = {

    xdg.configFile."nvim/queries/go/injections.scm".text =
      builtins.readFile ./lua/myLuaConf/syntax/go.scm;
    xdg.configFile."nvim/queries/templ/injections.scm".text =
      builtins.readFile ./lua/myLuaConf/syntax/html.scm;

    # this value, nixCats is the defaultPackageName you pass to mkNixosModules
    # it will be the namespace for your options.
    nixCats = {
      # these are some of the options. For the rest see
      # :help nixCats.flake.outputs.utils.mkNixosModules
      # you do not need to use every option here, anything you do not define
      # will be pulled from the flake instead.
      enable = true;
      nixpkgs_version = inputs.nixpkgs;
      # this will add the overlays from ./overlays and also,
      # add any plugins in inputs named "plugins-pluginName" to pkgs.neovimPlugins
      # It will not apply to overall system, just nixCats.
      addOverlays =
        # (import ./overlays inputs) ++
        [ (utils.standardPluginOverlay inputs) ];
      packageNames = [
        "regularCats"
        "nixCats"
      ];

      luaPath = "${./.}";

      # categoryDefinitions.replace will replace the whole categoryDefinitions with a new one
      categoryDefinitions.replace =
        {
          pkgs,
          settings,
          categories,
          extra,
          name,
          mkNvimPlugin,
          ...
        }@packageDef:
        {
          lspsAndRuntimeDeps = {
            general = with pkgs; [
              universal-ctags
              ripgrep
              fd
              stdenv.cc.cc
            ];
            css = with pkgs; [
              stylelint
              prettierd
              rustywind
              tailwindcss-language-server
            ];
            docker = with pkgs; [
              dockerfile-language-server-nodejs
              docker-compose-language-service
              hadolint
            ];
            html = with pkgs; [
              htmlhint
              rubyPackages_3_4.htmlbeautifier
              htmx-lsp
              vscode-langservers-extracted
              svelte-language-server
            ];
            go = with pkgs; [
              go
              golangci-lint
              delve
              gopls
              go-tools
              gotools
              gotestsum
            ];
            json = with pkgs; [ nodePackages_latest.vscode-json-languageserver ];
            lua = with pkgs; [
              stylua
              luajitPackages.luacheck
              lua-language-server
            ];
            markdown = with pkgs; [
              marksman
              markdownlint-cli2
            ];
            nix = with pkgs; [
              nixd
              nixfmt-rfc-style
              statix
              nix-doc
            ];
            python = with pkgs; [
              isort
              black
              pyright
            ];
            sql = with pkgs; [
              sqls
              sqlfluff
            ];
            terraform = with pkgs; [
              terraform
              terraform-lsp
            ];
            toml = with pkgs; [ taplo ];
            templ = with pkgs; [ templ ];
            typescript = with pkgs; [
              typescript-language-server
              eslint
            ];
            yaml = with pkgs; [
              yamlfmt
              yamllint
              yaml-language-server
            ];
          };
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
            ];
            test = with pkgs.vimPlugins; [
              neotest
              neotest-golang
              nvim-coverage
              vim-dotenv
            ];
            lint = with pkgs.vimPlugins; [ nvim-lint ];
            format = with pkgs.vimPlugins; [ conform-nvim ];
            neonixdev = with pkgs.vimPlugins; [ lazydev-nvim ];
            general = {
              ai = with pkgs.vimPlugins; [
                copilot-lua
                CopilotChat-nvim
                avante-nvim
              ];
              cmp = with pkgs.vimPlugins; [
                blink-cmp
                blink-compat
                blink-ripgrep-nvim
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
              ];
              treesitter = with pkgs.vimPlugins; [
                nvim-treesitter-textobjects
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
                pkgs.neovimPlugins.webify-nvim
              ];
              diagnostics = with pkgs.vimPlugins; [ trouble-nvim ];
              editor = with pkgs.vimPlugins; [
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
              ui = with pkgs.vimPlugins; [
                indent-blankline-nvim
                lualine-nvim
                dropbar-nvim
                helpview-nvim
                tailwind-tools-nvim
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
        };

      # see :help nixCats.flake.outputs.packageDefinitions
      packageDefinitions.replace = {
        nixCats =
          { pkgs, ... }:
          {
            settings = {
              wrapRc = true;
              suffix-path = true;
              suffix-LD = true;
              aliases = [ "nvim" ];
              configDirName = "nvim";
              # neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
            };
            categories = {
              general = true;
              neonixdev = true;

              css = true;
              docker = true;
              html = true;
              ts = true;
              go = true;
              json = true;
              lua = true;
              markdown = true;
              nix = true;
              python = true;
              sql = true;
              terraform = true;
              toml = true;
              templ = true;
              typescript = true;
              yaml = true;

              ai = true;
              diagnostics = true;
              editor = true;
              debug = true;
              test = true;
              lint = true;
              format = true;
              git = true;
              ui = true;
              extra = true;

              lspDebugMode = false;
              themer = true;
              colorscheme = "catppuccin";
            };
            extra = {
              nixdExtras = {
                inherit (inputs) nixpkgs;
                flake-path = inputs.self;
              };
            };
          };

        regularCats =
          { pkgs, ... }:
          {
            settings = {
              wrapRc = false;
              suffix-path = true;
              suffix-LD = true;
              unwrappedCfgPath = "${config.home.homeDirectory}/nixicle/modules/home/cli/editors/neovim";
              configDirName = "nvim";
              neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
            };
            categories = {
              general = true;
              neonixdev = true;

              css = true;
              docker = true;
              html = true;
              go = true;
              ts = true;
              json = true;
              lua = true;
              markdown = true;
              nix = true;
              python = true;
              sql = true;
              terraform = true;
              toml = true;
              templ = true;
              typescript = true;
              yaml = true;

              ai = true;
              diagnostics = true;
              editor = true;
              debug = true;
              test = true;
              lint = true;
              format = true;
              git = true;
              ui = true;
              extra = true;

              lspDebugMode = false;
              themer = true;
              colorscheme = "catppuccin";
            };
            extra = {
              nixdExtras = {
                inherit (inputs) nixpkgs;
                flake-path = inputs.self;
              };
            };
          };
      };
    };
  };

}
