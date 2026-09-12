{
  inputs,
  lib,
  den,
  ...
}:
let
  inherit ((import ../lib { inherit inputs lib; })) extendedLib;
  unfreePackages = import ../lib/unfree-packages.nix;

  overlays = [
    inputs.nur.overlays.default
    inputs.niri.overlays.niri
    (_final: prev: {
      zjstatus = inputs.zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
    })
    extendedLib.nixicle.nixicleOverlay
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

  mkPiInstantiate =
    { modules }:
    inputs.nixos-raspberrypi.lib.nixosSystem {
      inherit (inputs) nixpkgs;
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
      hmExtendedLib = extendedLib.extend (_self: _super: { hm = hmLib; });
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        inherit overlays;
        config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfreePackages;
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

  haseebUser = {
    authorizedKeys = extendedLib.nixicle.authorizedKeys;
    email = "hello@haseebmajid.dev";
    signingKey = "~/.ssh/id_ed25519.pub";
  };
in
{
  den = {
    aspects.haseeb = {
      includes = [
        den.batteries.primary-user
        (den.batteries.user-shell "fish")
      ];
    };

    hosts.x86_64-linux = {
      framework = {
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

      vm = {
        instantiate = mkInstantiate;
        users.haseeb = haseebUser;
      };

      desktop = {
        autologin = false;
        instantiate = mkInstantiate;
        users.haseeb = haseebUser;
      };

      nas = {
        instantiate = mkInstantiate;
        users.haseeb = haseebUser;
      };

      vps = {
        instantiate = mkInstantiate;
      };
    };

    hosts.aarch64-linux = {
      rpi = {
        instantiate = mkPiInstantiate;
      };
    };

    homes = {
      x86_64-linux = {
        "haseebmajid@dell" = {
          isLaptop = true;
          instantiate = mkHomeInstantiate;
        };

        "haseeb@framework" = {
          isLaptop = true;
          instantiate = mkHomeInstantiate;
        };

        "haseeb@desktop" = {
          instantiate = mkHomeInstantiate;
        };
      };
    };
  };
}
