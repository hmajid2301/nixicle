{
  inputs,
  lib,
  den,
  ...
}:
let
  extendedLib = lib.extend (
    self: _super: {
      nixicle = import ../lib {
        inherit inputs;
        lib = self;
      };
    }
  );
in
{
  den = {
    schema.user = {
      includes = [
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

    schema.home.includes = [
      (
        { home, ... }:
        {
          homeManager =
            { pkgs, ... }:
            {
              _module.args.host = home.hostName or "unknown";
              nix.package = pkgs.nix;
            };
        }
      )
    ];

    schema.host =
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
          nixicle = extendedLib.nixicle.importPackages final ../packages // { };
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
