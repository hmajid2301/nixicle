{ inputs, lib, den, ... }:
{
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
