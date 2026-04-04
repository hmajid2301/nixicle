{ inputs, lib, den, ... }:
let
  mkInstantiate =
    { modules }:
    let
      extendedLib = lib.extend (self: super: {
        nixicle = import ../old/lib {
          inherit inputs;
          lib = self;
        };
      });
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit modules;
      specialArgs = {
        inherit inputs;
        lib = extendedLib;
      };
    };
in
{
  imports = [
    inputs.den.flakeModule
    inputs.den.flakeOutputs.nixosConfigurations
    inputs.den.flakeOutputs.homeConfigurations
  ];

  _module.args.__findFile = den.lib.__findFile;

  den.ctx.user.includes = [ den._.mutual-provider ];

  den.hosts.x86_64-linux.framework = {
    isLaptop = true;
    primaryDisplay = {
      name = "eDP-1";
      width = 2256;
      height = 1504;
      refresh = 120;
    };
    instantiate = mkInstantiate;
    users.haseeb = { };
  };

  den.hosts.x86_64-linux.vm = {
    instantiate = mkInstantiate;
    users.haseeb = { };
  };

  den.homes.x86_64-linux."haseeb@framework" = { };
  den.homes.x86_64-linux."haseeb@vm" = { };

  den.schema.user = { lib, ... }: {
    config.classes = lib.mkDefault [ "homeManager" ];
  };

  den.schema.host = { lib, ... }: {
    options.isLaptop = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    options.primaryDisplay = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
    };
  };

  den.default = {
    includes = [
      den._.define-user
      den._.hostname
    ];
  };

  # NOTE: do NOT include home-manager.nixosModules here — den handles HM integration automatically
  den.default.nixos = { ... }: {
    imports = [
      inputs.stylix.nixosModules.stylix
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.impermanence.nixosModules.impermanence
      inputs.sops-nix.nixosModules.sops
      inputs.authentik-nix.nixosModules.default
      inputs.tangled.nixosModules.knot
      inputs.tangled.nixosModules.spindle
      inputs.nixflix.nixosModules.nixflix
      inputs.niri.nixosModules.niri
      inputs.goroutinely.nixosModules.default
      inputs.disko.nixosModules.disko
      inputs.nix-topology.nixosModules.default
    ];
  };

  den.default.homeManager = { ... }: {
    imports = [
      inputs.dankMaterialShell.homeModules.dank-material-shell
      inputs.noctalia.homeModules.default
      inputs.sops-nix.homeManagerModules.sops
      inputs.stylix.homeModules.stylix
      inputs.catppuccin.homeModules.catppuccin
      inputs.nix-index-database.homeModules.nix-index
      inputs.pam-shim.homeModules.default
    ];
  };
}
