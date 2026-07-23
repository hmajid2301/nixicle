{ inputs, lib, ... }:
let
  extendedLib = lib.extend (
    self: _super: {
      nixicle = import ../lib {
        inherit inputs;
        lib = self;
      };
    }
  );

  overlays = [
    inputs.nur.overlays.default
    inputs.niri.overlays.niri
    (_final: prev: {
      zjstatus = inputs.zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
    })
    (final: prev: {
      nixicle = extendedLib.nixicle.importPackages final ../packages // { };
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

  mkPiInstantiate =
    { modules }:
    inputs.nixos-raspberrypi.lib.nixosSystem {
      nixpkgs = inputs.nixpkgs;
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

  haseebUser = {
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuM4bCeJq0XQ1vd/iNK650Bu3wPVKQTSB0k2gsMKhdE hello@haseebmajid.dev"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwAamg3cSHP+91grc7qmrwNoPpbxD/IMi8MhqpptuM2 hello@haseebmajid.dev"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBZsm7CzZ50x8eaUrXaMmNRE2J9qK9E9X9vFHuv04E1V hello@haseebmajid.dev"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLrECFz5PQ5D2+QXomsLK9HcZhHzcBUIDGkiI94c6Ux hello@haseebmajid.dev"
    ];
    email = "hello@haseebmajid.dev";
    signingKey = "~/.ssh/id_ed25519.pub";
  };
in
{
  den = {
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

      framebox = {
        instantiate = mkInstantiate;
        users.haseeb = haseebUser;
      };

      desktop = {
        instantiate = mkInstantiate;
        users.haseeb = haseebUser;
      };

      gateway = {
        instantiate = mkInstantiate;
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

    homes.x86_64-linux."haseebmajid@dell" = {
      instantiate = mkHomeInstantiate;
    };

    homes.x86_64-linux."haseeb@framework" = {
      instantiate = mkHomeInstantiate;
    };

    homes.x86_64-linux."haseeb@framebox" = {
      instantiate = mkHomeInstantiate;
    };

    homes.x86_64-linux."haseeb@desktop" = {
      instantiate = mkHomeInstantiate;
    };
  };
}
