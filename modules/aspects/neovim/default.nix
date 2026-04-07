{ den, inputs, ... }:
let
  inherit (inputs.nixCats) utils;
in
{
  flake-file.inputs = {
    nixCats.url = "github:BirdeeHub/nixCats-nvim";

    # Plugin sources declared as top-level flake inputs — required by
    # utils.standardPluginOverlay which scans inputs for plugins-* prefixed keys.
    plugins-cmp-dbee = {
      url = "github:MattiasMTS/cmp-dbee";
      flake = false;
    };
    plugins-gx-nvim = {
      url = "github:chrishrb/gx.nvim";
      flake = false;
    };
    plugins-maximize-nvim = {
      url = "github:declancm/maximize.nvim";
      flake = false;
    };
    plugins-nvim-dap-view = {
      url = "github:igorlfs/nvim-dap-view";
      flake = false;
    };
    plugins-webify-nvim = {
      url = "github:pabloariasal/webify.nvim";
      flake = false;
    };
    plugins-templ-goto-definition = {
      url = "github:catgoose/templ-goto-definition";
      flake = false;
    };
    plugins-tiny-code-actions = {
      url = "github:rachartier/tiny-code-action.nvim";
      flake = false;
    };
    plugins-cmp-go-deep = {
      url = "github:samiulsami/cmp-go-deep";
      flake = false;
    };
    plugins-inline-edit = {
      url = "github:AndrewRadev/inline_edit.vim";
      flake = false;
    };
    plugins-neotest-golang = {
      url = "github:fredrikaverpil/neotest-golang";
      flake = false;
    };
    plugins-neotest = {
      url = "github:nvim-neotest/neotest";
      flake = false;
    };
    plugins-warp-nvim = {
      url = "github:y3owk1n/warp.nvim";
      flake = false;
    };

    # Not a plugin — used for XDG config files.
    oxy2dev-nvim-scripts = {
      url = "github:OXY2DEV/nvim";
      flake = false;
    };
  };

  den.aspects.neovim = {
    homeManager =
      { config, lib, pkgs, ... }:
      let
        configModule = import ./_config.nix { inherit config lib pkgs inputs; };
        lspAndToolsModule = import ./_lsp-and-tools.nix { inherit pkgs; };
        pluginsModule = import ./_plugins.nix;
        packageDefinitionsModule = import ./_package-definitions.nix { inherit config inputs; };
      in
      {
        imports = [ inputs.nixCats.homeModule ];

        nix.settings = {
          extra-substituters = [ "https://nix-community.cachix.org" ];
          extra-trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
        };

        inherit (configModule) xdg;

        nixCats = configModule.nixCats // {
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
            (lspAndToolsModule // (pluginsModule { inherit pkgs categories; }));

          inherit (packageDefinitionsModule) packageDefinitions;
        };
      };
  };
}
