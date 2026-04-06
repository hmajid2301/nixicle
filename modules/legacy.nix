{ inputs, lib, den, ... }:
{
  # niri desktop extras
  flake-file.inputs.nfsm = {
    url = "github:gvolpe/nfsm";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Inject HM settings per user context.
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
