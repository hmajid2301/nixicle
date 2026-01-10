{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.tangled;
in
{
  imports = [
    ./knot.nix
    ./spindle.nix
  ];

  options.services.nixicle.tangled = {
    enable = mkBoolOpt false "Enable Tangled services (knot and spindle)";

    owner = mkOption {
      type = types.str;
      example = "did:plc:qfpnj4og54vl56wngdriaxug";
      description = "DID of owner for all Tangled services";
    };

    hostname = mkOption {
      type = types.str;
      example = "tangled.example.com";
      description = "Base hostname for Tangled services";
    };

    knotPackage = mkOption {
      type = types.package;
      default = inputs.tangled.packages.${pkgs.system}.knot or pkgs.tangled-knot;
      description = "Package to use for knot";
    };

    spindlePackage = mkOption {
      type = types.package;
      default = inputs.tangled.packages.${pkgs.system}.spindle or pkgs.tangled-spindle;
      description = "Package to use for spindle";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.nixicle.tangled.knot = {
        enable = true;
        package = cfg.knotPackage;
        server = {
          owner = cfg.owner;
          hostname = cfg.hostname;
        };
      };

      services.nixicle.tangled.spindle = {
        enable = true;
        package = cfg.spindlePackage;
        server = {
          owner = cfg.owner;
          hostname = "spindle.${cfg.hostname}";
        };
      };
    }
    {
      services.traefik.dynamicConfigOptions.http = mkMerge [
        (lib.nixicle.mkTraefikService {
          name = "tangled-knot";
          port = 5555;
        })
        (lib.nixicle.mkTraefikService {
          name = "tangled-spindle";
          port = 6555;
        })
      ];
    }
  ]);
}
