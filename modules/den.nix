{ inputs, lib, den, ... }:
let
  extendedLib = lib.extend (self: super: {
    nixicle = import ../lib {
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
      nixicle = extendedLib.nixicle.importPackages final ../packages // {
        zellij-mcp = prev.callPackage ../packages/zellij-mcp {
          inherit inputs;
        };
      };
    })
  ];

  mkInstantiate = { modules }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit modules;
      specialArgs = { inherit inputs; lib = extendedLib; };
    };

  mkHomeInstantiate = { modules, ... }:
    let
      hmLib = inputs.home-manager.lib.hm;
      hmExtendedLib = extendedLib.extend (self: super: { hm = hmLib; });
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
        inherit overlays;
      };
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs; lib = hmExtendedLib; };
      inherit modules;
    };
in
{
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.sops-nix = {
    url = "github:mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.stylix.url = "github:danth/stylix";
  flake-file.inputs.catppuccin.url = "github:catppuccin/nix";
  flake-file.inputs.nur.url = "github:nix-community/NUR";
  flake-file.inputs.gomod2nix = {
    url = "github:nix-community/gomod2nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.nix-index-database.url = "github:nix-community/nix-index-database";
  flake-file.inputs.nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
  flake-file.inputs.noctalia = {
    url = "github:noctalia-dev/noctalia-shell";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.dankMaterialShell = {
    url = "github:AvengeMedia/DankMaterialShell";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.zjstatus.url = "github:dj95/zjstatus";
  flake-file.inputs.get-shit-done = {
    url = "github:gsd-build/get-shit-done/v1.21.1";
    flake = false;
  };
  flake-file.inputs.nixflix = {
    url = "github:kiriwalawren/nixflix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.zellij-mcp = {
    url = "github:GitJuhb/zellij-mcp-server";
    flake = false;
  };
  flake-file.inputs.comma = {
    url = "github:nix-community/comma";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.fenix = {
    url = "github:nix-community/fenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake-file.outputs = "flake-module";

  imports = [
    inputs.flake-file.flakeModules.flake
    inputs.den.flakeModule
    inputs.den.flakeOutputs.nixosConfigurations
    inputs.den.flakeOutputs.homeConfigurations
  ];

  _module.args.__findFile = den.lib.__findFile;

  den.ctx.user.includes = [ den._.mutual-provider ];
  den.ctx.home.includes = [
    den._.mutual-provider
    ({ home, ... }: {
      homeManager = { ... }: {
        _module.args.host = home.hostName or "unknown";
      };
    })
  ];

  den.hosts.x86_64-linux.framework = {
    isLaptop = true;
    autologin = false;
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

  den.hosts.x86_64-linux.framebox = {
    instantiate = mkInstantiate;
    users.haseeb = { };
  };

  den.hosts.x86_64-linux.workstation = {
    instantiate = mkInstantiate;
    users.haseeb = { };
  };

  den.hosts.x86_64-linux.vps = {
    instantiate = mkInstantiate;
  };

  den.homes.x86_64-linux."haseebmajid@dell" = {
    instantiate = mkHomeInstantiate;
  };


  den.schema.user = { lib, ... }: {
    config.classes = lib.mkDefault [ "homeManager" ];
  };

  den.schema.host = { lib, ... }: {
    options.isLaptop = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    options.autologin = lib.mkOption {
      type = lib.types.bool;
      default = true;
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
    nixpkgs.overlays = overlays;
    nixpkgs.config.allowUnfree = true;
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
