{ inputs, lib, den, ... }:
{
  # nixCats neovim setup — plugins-* inputs are scanned by utils.standardPluginOverlay inputs
  flake-file.inputs.nixCats.url = "github:BirdeeHub/nixCats-nvim";
  flake-file.inputs.oxy2dev-nvim-scripts = {
    url = "github:OXY2DEV/nvim";
    flake = false;
  };
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

  # niri desktop extras
  flake-file.inputs.nfsm = {
    url = "github:gvolpe/nfsm";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # AI tools
  flake-file.inputs.nix-playwright-mcp = {
    url = "github:benjaminkitt/nix-playwright-mcp";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.opencode-antigravity-auth = {
    url = "github:NoeFabris/opencode-antigravity-auth/v1.6.0";
    flake = false;
  };

  den.default.homeManager = { ... }: {
    imports = [
      (inputs.import-tree.match ".*/default\\.nix" ../old/modules/home)
    ];
  };

  # Inject HM settings and host arg needed by old bridge modules.
  # Runs per user context so it only applies to hosts that actually have HM users.
  den.ctx.user.includes = [
    ({ host, user, ... }: {
      nixos.home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs; };
        users.${user.userName}._module.args.host = host.hostName;
      };
    })
  ];
}
