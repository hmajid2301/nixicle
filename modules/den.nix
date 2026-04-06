{
  inputs,
  lib,
  den,
  ...
}:
let
  haseebUser = {
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuM4bCeJq0XQ1vd/iNK650Bu3wPVKQTSB0k2gsMKhdE hello@haseebmajid.dev"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev"
    ];
    email = "hello@haseebmajid.dev";
    signingKey = "~/.ssh/id_ed25519.pub";
  };

  extendedLib = lib.extend (
    self: super: {
      nixicle = import ../lib {
        inherit inputs;
        lib = self;
      };
    }
  );

  # Overlays for mkHomeInstantiate (standalone HM builds like dell).
  # NixOS hosts get overlays via nixpkgs.overlays in aspect files instead.
  overlays = [
    inputs.nur.overlays.default
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

  mkInstantiate =
    { modules }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit modules;
      specialArgs = {
        inherit inputs;
        lib = extendedLib;
      };
    };

  mkHomeInstantiate =
    { modules, ... }:
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
      extraSpecialArgs = {
        inherit inputs;
        lib = hmExtendedLib;
      };
      inherit modules;
    };
in
{
  flake-file.inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  flake-file.inputs.den.url = "github:vic/den";
  flake-file.inputs.import-tree.url = "github:vic/import-tree";
  flake-file.inputs.flake-file.url = "github:vic/flake-file";
  flake-file.inputs.flake-parts = {
    url = "github:hercules-ci/flake-parts";
    inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  # home-manager: used in mkHomeInstantiate
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = [
    inputs.flake-file.flakeModules.dendritic
    inputs.den.flakeModule
    (inputs.import-tree.match ".*/default\\.nix" ../hosts)
  ];

  _module.args.__findFile = den.lib.__findFile;

  den.ctx.user.includes = [
    den._.mutual-provider
    (
      { host, user, ... }:
      {
        nixos.home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs; };
          users.${user.userName}._module.args.host = host.hostName;
        };
      }
    )
  ];
  den.ctx.home.includes = [
    den._.mutual-provider
    (
      { home, ... }:
      {
        homeManager =
          { ... }:
          {
            _module.args.host = home.hostName or "unknown";
          };
      }
    )
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
    users.haseeb = haseebUser;
  };

  den.hosts.x86_64-linux.vm = {
    instantiate = mkInstantiate;
    users.haseeb = haseebUser;
  };

  den.hosts.x86_64-linux.framebox = {
    instantiate = mkInstantiate;
    users.haseeb = haseebUser;
  };

  den.hosts.x86_64-linux.workstation = {
    instantiate = mkInstantiate;
    users.haseeb = haseebUser;
  };

  den.hosts.x86_64-linux.vps = {
    instantiate = mkInstantiate;
  };

  den.homes.x86_64-linux."haseebmajid@dell" = {
    instantiate = mkHomeInstantiate;
  };

  den.schema.user =
    { lib, ... }:
    {
      config.classes = lib.mkDefault [ "homeManager" ];
      options.authorizedKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "SSH public keys to add to authorized_keys for this user.";
      };
      options.email = lib.mkOption {
        type = lib.types.str;
        default = "hello@haseebmajid.dev";
        description = "Primary email address used for git commits and notifications.";
      };
      options.signingKey = lib.mkOption {
        type = lib.types.str;
        default = "~/.ssh/id_ed25519.pub";
        description = "Path to the SSH public key used for git commit signing.";
      };
    };

  den.schema.host =
    { lib, ... }:
    {
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

  den.default.nixos =
    { ... }:
    {
      # nixicle packages overlay (needs extendedLib so defined here).
      # nur overlay in common.nix; niri/zjstatus in niri.nix.
      nixpkgs.overlays = [
        (final: prev: {
          inherit (inputs) get-shit-done;
          nixicle = extendedLib.nixicle.importPackages final ../packages // {
            zellij-mcp = prev.callPackage ../packages/zellij-mcp {
              inherit inputs;
            };
          };
        })
      ];
      nixpkgs.config.allowUnfree = true;
      imports = [
        inputs.sops-nix.nixosModules.sops
        inputs.disko.nixosModules.disko
        inputs.nix-topology.nixosModules.default
      ];
    };
}
