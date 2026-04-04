{ inputs, lib, den, ... }:
let
  extendedLib = lib.extend (self: super: {
    nixicle = import ../old/lib {
      inherit inputs;
      lib = self;
    };
  });

  overlays = [
    inputs.gomod2nix.overlays.default
    inputs.nur.overlays.default
    inputs.nix-topology.overlays.default
    inputs.niri.overlays.niri
    (final: prev: {
      zjstatus = inputs.zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
    })
    (final: prev: {
      inherit (inputs) get-shit-done;
      nixicle = extendedLib.nixicle.importPackages final ../old/packages // {
        zellij-mcp = prev.callPackage ../old/packages/zellij-mcp {
          inherit inputs;
        };
      };
    })
  ];
in
{
  den.default.nixos = { ... }: {
    imports = [
      (inputs.import-tree.match ".*/default\\.nix" ../old/modules/nixos)
    ];
    nixpkgs.overlays = overlays;
    nixpkgs.config.allowUnfree = true;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;

    # Pass inputs into HM modules (old HM modules reference inputs directly)
    home-manager.extraSpecialArgs = { inherit inputs; };
  };

  den.default.homeManager = { ... }: {
    imports = [
      (inputs.import-tree.match ".*/default\\.nix" ../old/modules/home)
    ];
  };

  # Old HM modules reference `host` as a string arg — inject it so they keep working.
  den.ctx.user.includes = [
    ({ host, user, ... }: {
      nixos.home-manager.users.${user.userName}._module.args.host = host.hostName;
    })
  ];
}
