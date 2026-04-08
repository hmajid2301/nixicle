{ den, inputs, ... }:
{
  flake-file.inputs = {
    nix-wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

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

    oxy2dev-nvim-scripts = {
      url = "github:OXY2DEV/nvim";
      flake = false;
    };
  };

  den.aspects.neovim = {
    homeManager =
      { config, lib, pkgs, ... }:
      {
        imports = [ inputs.nix-wrapper-modules.homeModules.neovim ];

        nix.settings = {
          extra-substituters = [ "https://nix-community.cachix.org" ];
          extra-trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
        };

        xdg.configFile = {
          "nvim/queries/go/injections.scm".text =
            builtins.readFile ./lua/config/syntax/go.scm;
          "nvim/queries/templ/injections.scm".text =
            builtins.readFile ./lua/config/syntax/html.scm;
          "nvim/doc/nixicle.txt".text =
            builtins.readFile ./doc/nixicle.txt;

          "nvim/lua/scripts/lsp_hover.lua".source =
            "${inputs.oxy2dev-nvim-scripts}/lua/scripts/lsp_hover.lua";
          "nvim/lua/scripts/diagnostics.lua".source =
            "${inputs.oxy2dev-nvim-scripts}/lua/scripts/diagnostics.lua";
        };

        wrappers.neovim = {
          enable = true;
          imports = [ (import ./_nix inputs) ];
          _module.args.stylixColors =
            let
              raw = config.lib.stylix.colors.withHashtag or { };
            in
            lib.filterAttrs (_: v: builtins.isString v) raw;
        };
      };
  };
}
