{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.banterbus;

  mkInstance = name: instanceCfg: {
    banterbusSrc = pkgs.fetchFromGitLab {
      owner = "hmajid2301";
      repo = "banterbus";
      rev = instanceCfg.version;
      hash = instanceCfg.hash;
    };
    banterbus = (import (mkInstance name instanceCfg).banterbusSrc { inherit pkgs; }).packages.${pkgs.system}.default;
  };
in
{
  options.services.nixicle.banterbus = with types; {
    enable = mkBoolOpt false "Whether or not to enable BanterBus service";

    instances = mkOption {
      type = attrsOf (submodule {
        options = {
          version = mkOption {
            type = str;
            description = "Git revision to use";
          };

          hash = mkOption {
            type = str;
            description = "Hash of the source";
          };

          port = mkOption {
            type = int;
            description = "Port to run BanterBus on";
          };

          domain = mkOption {
            type = str;
            description = "Domain for this instance";
          };

          redis = {
            address = mkOption {
              type = str;
              default = "localhost:6379";
              description = "Redis server address";
            };
          };

          jwt = {
            jwksUrl = mkOption {
              type = str;
              description = "JWKS URL for JWT verification";
            };

            adminGroup = mkOption {
              type = str;
              default = "admin";
              description = "JWT group for admin access";
            };
          };
        };
      });
      default = {};
      description = "BanterBus instances to run";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.postgresql = {
        ensureDatabases = mapAttrsToList (name: _: "banterbus_${name}") cfg.instances;
        ensureUsers = mapAttrsToList (name: _: {
          name = "banterbus_${name}";
          ensureDBOwnership = true;
        }) cfg.instances;
      };

      users.users = mapAttrs' (name: _: nameValuePair "banterbus_${name}" {
        isSystemUser = true;
        group = "banterbus_${name}";
      }) cfg.instances;

      users.groups = mapAttrs' (name: _: nameValuePair "banterbus_${name}" {}) cfg.instances;

      systemd.services = mapAttrs' (name: instanceCfg:
        let
          instance = mkInstance name instanceCfg;
        in
        nameValuePair "banterbus_${name}" {
          description = "BanterBus ${name} trivia game service";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" "postgresql.service" "redis.service" ];
          requires = [ "postgresql.service" "redis.service" ];

          serviceConfig = {
            Type = "simple";
            User = "banterbus_${name}";
            Group = "banterbus_${name}";
            ExecStart = "${instance.banterbus}/bin/banterbus";
            Restart = "on-failure";
            RestartSec = "5s";

            Environment = [
              "BANTERBUS_DB_USERNAME=banterbus_${name}"
              "BANTERBUS_DB_HOST=/run/postgresql"
              "BANTERBUS_DB_PORT=5432"
              "BANTERBUS_DB_NAME=banterbus_${name}"
              "BANTERBUS_REDIS_ADDRESS=${instanceCfg.redis.address}"
              "BANTERBUS_JWKS_URL=${instanceCfg.jwt.jwksUrl}"
              "BANTERBUS_JWT_ADMIN_GROUP=${instanceCfg.jwt.adminGroup}"
              "BANTERBUS_SERVER_PORT=${toString instanceCfg.port}"
            ];

            PrivateTmp = true;
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
          };
        }
      ) cfg.instances;

      networking.firewall.allowedTCPPorts = mapAttrsToList (_: instanceCfg: instanceCfg.port) cfg.instances;
    }

    {
      services.cloudflared.tunnels = mkIf config.services.nixicle.cloudflare.enable {
        ${config.services.nixicle.cloudflare.tunnelId}.ingress =
          mapAttrs' (_: instanceCfg: nameValuePair instanceCfg.domain "http://localhost:${toString instanceCfg.port}") cfg.instances;
      };
    }
  ]);
}

