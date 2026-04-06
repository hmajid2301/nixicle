{ den, inputs, ... }:
let
  inherit (inputs.nixCats) utils;
in
{
  flake-file.inputs.nixCats.url = "github:BirdeeHub/nixCats-nvim";

  # Plugin sources declared as top-level flake inputs — required by
  # utils.standardPluginOverlay which scans inputs for plugins-* prefixed keys.
  flake-file.inputs.plugins-cmp-dbee = {
    url = "github:MattiasMTS/cmp-dbee";
    flake = false;
  };
  flake-file.inputs.plugins-gx-nvim = {
    url = "github:chrishrb/gx.nvim";
    flake = false;
  };
  flake-file.inputs.plugins-maximize-nvim = {
    url = "github:declancm/maximize.nvim";
    flake = false;
  };
  flake-file.inputs.plugins-nvim-dap-view = {
    url = "github:igorlfs/nvim-dap-view";
    flake = false;
  };
  flake-file.inputs.plugins-webify-nvim = {
    url = "github:pabloariasal/webify.nvim";
    flake = false;
  };
  flake-file.inputs.plugins-templ-goto-definition = {
    url = "github:catgoose/templ-goto-definition";
    flake = false;
  };
  flake-file.inputs.plugins-tiny-code-actions = {
    url = "github:rachartier/tiny-code-action.nvim";
    flake = false;
  };
  flake-file.inputs.plugins-cmp-go-deep = {
    url = "github:samiulsami/cmp-go-deep";
    flake = false;
  };
  flake-file.inputs.plugins-inline-edit = {
    url = "github:AndrewRadev/inline_edit.vim";
    flake = false;
  };
  flake-file.inputs.plugins-neotest-golang = {
    url = "github:fredrikaverpil/neotest-golang";
    flake = false;
  };
  flake-file.inputs.plugins-neotest = {
    url = "github:nvim-neotest/neotest";
    flake = false;
  };
  flake-file.inputs.plugins-warp-nvim = {
    url = "github:y3owk1n/warp.nvim";
    flake = false;
  };

  # Not a plugin — used for XDG config files.
  flake-file.inputs.oxy2dev-nvim-scripts = {
    url = "github:OXY2DEV/nvim";
    flake = false;
  };

  den.aspects.neovim = {
    homeManager =
      { config, lib, pkgs, ... }:
      let
        configModule = import ./config.nix { inherit config lib pkgs inputs; };
        lspAndToolsModule = import ./lsp-and-tools.nix { inherit pkgs; };
        pluginsModule = import ./plugins.nix;
        packageDefinitionsModule = import ./package-definitions.nix { inherit config inputs; };
      in
      {
        imports = [ inputs.nixCats.homeModule ];

        nix.settings = {
          extra-substituters = [ "https://nix-community.cachix.org" ];
          extra-trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
        };

        xdg = configModule.xdg;

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

          packageDefinitions = packageDefinitionsModule.packageDefinitions;
        };
      };
  };
}
