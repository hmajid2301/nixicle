{
  config,
  lib,
  pkgs,
  inputs ? null,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.tangled;
in
{
  options.services.nixicle.tangled = {
    enable = mkBoolOpt false "Enable Tangled services (knot and spindle)";
  };

  config = mkIf cfg.enable {
    services = {
      tangled.knot = {
        enable = true;
        package = inputs.tangled.packages.${pkgs.stdenv.hostPlatform.system}.knot;
        server = {
          owner = "did:plc:reouqbpvl2kbkhvok2pwhlzg";
          hostname = "tangled.haseebmajid.dev";
        };
      };

      tangled.spindle = {
        enable = true;
        package = inputs.tangled.packages.${pkgs.stdenv.hostPlatform.system}.spindle;
        server = {
          owner = "did:plc:reouqbpvl2kbkhvok2pwhlzg";
          hostname = "spindle.haseebmajid.dev";
          secrets = {
            provider = "openbao";
            openbao = {
              proxyAddr = "http://127.0.0.1:8202";
              mount = "spindle";
            };
          };
        };
      };

      nixicle.nixery = {
        enable = true;
        port = 8091;
        channel = "nixos-unstable";
      };

      nixicle.openbao = {
        enable = true;
        proxy.enable = true;
      };

      cloudflared.tunnels = mkIf config.services.nixicle.cloudflare.enable {
        ${config.services.nixicle.cloudflare.tunnelId}.ingress = {
          "tangled.haseebmajid.dev" = {
            service = "http://localhost:5555";
          };
          "spindle.haseebmajid.dev" = {
            service = "http://localhost:6555";
          };
          "git.haseebmajid.dev" = {
            service = "ssh://localhost:22";
          };
        };
      };
    };

    environment.persistence."/persist" = mkIf config.system.impermanence.enable {
      directories = [
        {
          directory = "/home/git";
          user = "git";
          group = "git";
          mode = "0750";
        }
        {
          directory = "/var/lib/spindle";
          user = "root";
          group = "root";
          mode = "0755";
        }
      ];
    };
  };
}
