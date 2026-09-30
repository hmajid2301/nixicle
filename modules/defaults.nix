{
  inputs,
  lib,
  den,
  ...
}:
let
  inherit ((import ../lib { inherit inputs lib; })) extendedLib;
in
{
  imports = [ ./aspects/system/backup.nix ];

  den = {
    schema = {
      user = {
        includes = [
          (
            { host, user, ... }:
            {
              nixos.home-manager = {
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs; };
                users.${user.userName} = {
                  _module.args = {
                    host = host.hostName;
                    hostIsLaptop = host.isLaptop or false;
                  };
                  nixpkgs.overlays = [
                    extendedLib.nixicle.overlays.nur
                    extendedLib.nixicle.overlays.niri
                    extendedLib.nixicle.overlays.zjstatus
                    extendedLib.nixicle.overlays.nixicle
                  ];
                  nixpkgs.config.allowUnfreePredicate = extendedLib.nixicle.allowUnfreePredicate;
                };
              };
            }
          )
        ];
        imports = [
          (
            { lib, ... }:
            {
              config.classes = lib.mkDefault [ "homeManager" ];
              options = {
                authorizedKeys = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "SSH public keys to add to authorized_keys for this user.";
                };
                email = lib.mkOption {
                  type = lib.types.str;
                  default = "hello@haseebmajid.dev";
                  description = "Primary email address used for git commits and notifications.";
                };
                signingKey = lib.mkOption {
                  type = lib.types.str;
                  default = "~/.ssh/id_ed25519.pub";
                  description = "Path to the SSH public key used for git commit signing.";
                };
              };
            }
          )
        ];
      };

      home = {
        includes = [
          (
            { home, ... }:
            {
              homeManager =
                { pkgs, ... }:
                {
                  _module.args = {
                    host = home.hostName or "unknown";
                    hostIsLaptop = home.isLaptop or false;
                  };
                  nix.package = pkgs.nix;
                  nixpkgs.config.allowUnfreePredicate = extendedLib.nixicle.allowUnfreePredicate;
                };
            }
          )
        ];

        options = {
          isLaptop = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
        };
      };

      host =
        { lib, ... }:
        {
          options = {
            isLaptop = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            autologin = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };
            primaryDisplay = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = { };
            };
          };
        };
    };
  };

  den.default = {
    includes = [
      den._.define-user
      den._.hostname
      den.batteries.inputs'
      den.batteries.self'
    ];
  };

  den.default.nixos =
    { ... }:
    {
      # nixicle packages overlay (needs extendedLib so defined here).
      # nur overlay in common.nix; niri/zjstatus in niri.nix.
      nixpkgs.overlays = [ extendedLib.nixicle.nixicleOverlay ];
      nixpkgs.config.allowUnfreePredicate = extendedLib.nixicle.allowUnfreePredicate;
      imports = [
        ./aspects/system/identity-options.nix
        inputs.sops-nix.nixosModules.sops
        inputs.disko.nixosModules.disko
        inputs.nix-topology.nixosModules.default
      ];
    };
}
