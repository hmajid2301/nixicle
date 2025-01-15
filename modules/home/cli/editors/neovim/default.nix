# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
/*
# paste the inputs you don't have in this set into your main system flake.nix
# (lazy.nvim wrapper only works on unstable)
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  nixCats.url = "github:BirdeeHub/nixCats-nvim";
};

Then call this file with:
myNixCats = import ./path/to/this/dir { inherit inputs; };
And the new variable myNixCats will contain all outputs of the normal flake format.
You could put myNixCats.packages.${pkgs.system}.thepackagename in your packages list.
You could install them with the module and reconfigure them too if you want.
You should definitely re export them under packages.${system}.packagenames
from your system flake so that you can still run it via nix run from anywhere.

The following is just the outputs function from the flake template.
*/
{inputs, ...} @ attrs: let
  inherit (inputs) nixpkgs; # <-- nixpkgs = inputs.nixpkgsSomething;
  inherit (inputs.nixCats) utils;
  luaPath = "${./.}";
  forEachSystem = utils.eachSystem nixpkgs.lib.platforms.all;
  # the following extra_pkg_config contains any values
  # which you want to pass to the config set of nixpkgs
  # import nixpkgs { config = extra_pkg_config; inherit system; }
  # will not apply to module imports
  # as that will have your system values
  extra_pkg_config = {
    # allowUnfree = true;
  };
  dependencyOverlays =
    /*
    (import ./overlays inputs) ++
    */
    [
      # see :help nixCats.flake.outputs.overlays
      # This overlay grabs all the inputs named in the format
      # `plugins-<pluginName>`
      # Once we add this overlay to our nixpkgs, we are able to
      # use `pkgs.neovimPlugins`, which is a set of our plugins.
      (utils.standardPluginOverlay inputs)
      # add any flake overlays here.

      # when other people mess up their overlays by wrapping them with system,
      # you may instead call this function on their overlay.
      # it will check if it has the system in the set, and if so return the desired overlay
      # (utils.fixSystemizedOverlay inputs.codeium.overlays
      #   (system: inputs.codeium.overlays.${system}.default)
      # )
    ];

  categoryDefinitions = {
    pkgs,
    settings,
    categories,
    extra,
    name,
    mkNvimPlugin,
    ...
  } @ packageDef: {
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
        rustywind
      ];
      go = with pkgs; [
        golangci-lint
        delve
        gopls
        gotools
        gotestsum
      ];
      json = with pkgs; [
        nodePackages_latest.vscode-json-languageserver
      ];
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
        nixfmt
        statix
        nix-doc
      ];
      python = with pkgs; [
        isort
        black
        pyright
      ];
      sql = with pkgs; [
        sqlfluff
        sqls
      ];
      terraform = with pkgs; [
        terraform
        terraform-lsp
      ];
      toml = with pkgs; [
        taplo
      ];
      typescript = with pkgs; [
        typescript-language-server
      ];
      yaml = with pkgs; [
        yamlfmt
        yamllint
        yaml-language-server
      ];
    };

    startupPlugins = {
      debug = with pkgs.vimPlugins; [
        nvim-nio
      ];
      general = with pkgs.vimPlugins; {
        always = [
          lze
          vim-repeat
          plenary-nvim
        ];
        extra = [
          oil-nvim
          nvim-web-devicons
          auto-session
        ];
      };
      themer = with pkgs.vimPlugins; (
        builtins.getAttr (categories.colorscheme or "catppuccin") {
          "catppuccin" = catppuccin-nvim;
          "catppuccin-mocha" = catppuccin-nvim;
        }
      );
    };

    optionalPlugins = {
      debug = with pkgs.vimPlugins; [
        nvim-dap
        nvim-dap-ui
        nvim-dap-go
      ];
      test = with pkgs.vimPlugins; [
        neotest
        neotest-golang
      ];
      lint = with pkgs.vimPlugins; [
        nvim-lint
      ];
      format = with pkgs.vimPlugins; [
        conform-nvim
      ];
      neonixdev = with pkgs.vimPlugins; [
        lazydev-nvim
      ];
      general = {
        ai = with pkgs.vimPlugins; [
          CopilotChat-nvim
        ];
        cmp = with pkgs.vimPlugins; [
          # cmp stuff
          nvim-cmp
          luasnip
          friendly-snippets
          cmp_luasnip
          cmp-buffer
          cmp-path
          cmp-nvim-lua
          cmp-nvim-lsp
          cmp-cmdline
          cmp-nvim-lsp-signature-help
          cmp-cmdline-history
          lspkind-nvim
        ];
        treesitter = with pkgs.vimPlugins; [
          nvim-treesitter-textobjects
          nvim-treesitter.withAllGrammars
        ];
        telescope = with pkgs.vimPlugins; [
          telescope-fzf-native-nvim
          telescope-media-files-nvim
          telescope-nvim
        ];
        always = with pkgs.vimPlugins; [
          nvim-lspconfig
        ];
        git = with pkgs.vimPlugins; [
          gitsigns-nvim
          diffview-nvim
          advanced-git-search-nvim
          neogit
        ];
        diagnostics = with pkgs.vimPlugins; [
          trouble-nvim
        ];
        editor = with pkgs.vimPlugins; [
          mini-nvim
          refactoring-nvim
          arrow-nvim
          vim-illuminate
          nvim-navbuddy
          todo-comments-nvim
          grug-far-nvim
          smart-splits-nvim
          pkgs.neovimPlugins.gx-nvim
        ];
        extra = with pkgs.vimPlugins; [
          fidget-nvim
          # lualine-lsp-progress
          comment-nvim
          undotree
          nvim-dbee

          (pkgs.neovimPlugins.cmp-dbee.overrideAttrs {
            nvimSkipModule = [
              "cmp-dbee.connection"
              "cmp-dbee.source"
            ];
          })
        ];
        ui = with pkgs.vimPlugins; [
          indent-blankline-nvim
          lualine-nvim
          barbecue-nvim
          nvchad-ui
          base46
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
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
      test = [
        ''--set CATTESTVAR2 "It worked again!"''
      ];
    };

    # lists of the functions you would have passed to
    # python.withPackages or lua.withPackages

    # get the path to this python environment
    # in your lua config via
    # vim.g.python3_host_prog
    # or run from nvim terminal via :!<packagename>-python3
    extraPython3Packages = {
      test = _: [];
    };
    # populates $LUA_PATH and $LUA_CPATH
    extraLuaPackages = {
      test = [(_: [])];
    };
  };

  packageDefinitions = {
    nixCats = {pkgs, ...}: {
      settings = {
        wrapRc = true;
        aliases = ["vimCat"];
        configDirName = "nixCats-nvim";
        neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
      };
      categories = {
        general = true;
        neonixdev = true;

        css = true;
        docker = true;
        html = true;
        go = true;
        json = true;
        lua = true;
        markdown = true;
        nix = true;
        python = true;
        sql = true;
        terraform = true;
        toml = true;
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
          nixpkgs = nixpkgs;
          flake-path = inputs.self;
        };
      };
    };

    regularCats = {pkgs, ...}: {
      settings = {
        wrapRc = false;
        configDirName = "nixCats-nvim";
        aliases = ["testCat"];
        neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
      };
      categories = {
        general = true;
        neonixdev = true;

        css = true;
        docker = true;
        html = true;
        go = true;
        json = true;
        lua = true;
        markdown = true;
        nix = true;
        python = true;
        sql = true;
        terraform = true;
        toml = true;
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
          nixpkgs = nixpkgs;
          flake-path = inputs.self;
        };
      };
    };
  };
  # In this section, the main thing you will need to do is change the default package name
  # to the name of the packageDefinitions entry you wish to use as the default.
  defaultPackageName = "nixCats";
in
  # see :help nixCats.flake.outputs.exports
  forEachSystem (system: let
    nixCatsBuilder =
      utils.baseBuilder luaPath {
        inherit system dependencyOverlays extra_pkg_config nixpkgs;
      }
      categoryDefinitions
      packageDefinitions;
    defaultPackage = nixCatsBuilder defaultPackageName;
    # this is just for using utils such as pkgs.mkShell
    # The one used to build neovim is resolved inside the builder
    # and is passed to our categoryDefinitions and packageDefinitions
    pkgs = import nixpkgs {inherit system;};
  in {
    # this will make a package out of each of the packageDefinitions defined above
    # and set the default package to the one passed in here.
    packages = utils.mkAllWithDefault defaultPackage;

    # choose your package for devShell
    # and add whatever else you want in it.
    devShells = {
      default = pkgs.mkShell {
        name = defaultPackageName;
        packages = [defaultPackage];
        inputsFrom = [];
        shellHook = ''
        '';
      };
    };
  })
  // (let
    # we also export a nixos module to allow reconfiguration from configuration.nix
    nixosModule = utils.mkNixosModules {
      inherit
        defaultPackageName
        dependencyOverlays
        luaPath
        categoryDefinitions
        packageDefinitions
        extra_pkg_config
        nixpkgs
        ;
    };
    # and the same for home manager
    homeModule = utils.mkHomeModules {
      inherit
        defaultPackageName
        dependencyOverlays
        luaPath
        categoryDefinitions
        packageDefinitions
        extra_pkg_config
        nixpkgs
        ;
    };
  in {
    # these outputs will be NOT wrapped with ${system}

    # this will make an overlay out of each of the packageDefinitions defined above
    # and set the default overlay to the one named here.
    overlays =
      utils.makeOverlays luaPath {
        # we pass in the things to make a pkgs variable to build nvim with later
        inherit nixpkgs dependencyOverlays extra_pkg_config;
        # and also our categoryDefinitions
      }
      categoryDefinitions
      packageDefinitions
      defaultPackageName;

    nixosModules.default = nixosModule;
    homeModules.default = homeModule;

    inherit utils nixosModule homeModule;
    inherit (utils) templates;
  })
