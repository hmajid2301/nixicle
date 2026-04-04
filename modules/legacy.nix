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
  # Bridge: load all old NixOS modules into every host via import-tree
  den.default.nixos = { ... }: {
    imports = [
      (inputs.import-tree.match ".*/default\\.nix" ../old/modules/nixos)
    ];
    nixpkgs.overlays = overlays;
    nixpkgs.config.allowUnfree = true;

    # HM settings that were in mkHomeModule
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
  };

  # Bridge: load all old HM modules into every user's HM config
  den.default.homeManager = { ... }: {
    imports = [
      (inputs.import-tree.match ".*/default\\.nix" ../old/modules/home)
    ];
  };

  # Inject `host` (hostname string) into HM module args for backward compat.
  # Old HM modules use `host` (a string) to determine host-specific behaviour.
  den.ctx.user.includes = [
    ({ host, user, ... }: {
      nixos.home-manager.users.${user.userName}._module.args.host = host.hostName;
    })
  ];
}
