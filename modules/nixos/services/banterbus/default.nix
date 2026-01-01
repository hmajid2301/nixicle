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
  cfg = config.services.nixicle.banterbus;

  mkInstance = name: instanceCfg:
    let
      banterbus = inputs.banterbus.packages.${pkgs.system}.default;
    in
    {
      inherit banterbus;
    };
in
{
  options.services.nixicle.banterbus = with types; {
    enable = mkBoolOpt false "Whether or not to enable BanterBus service";

    jwksUrl = mkOption {
      type = str;
      default = "https://authentik.haseebmajid.dev/application/o/budibase/.well-known/openid-configuration";
      description = "JWKS URL for JWT verification";
    };

    adminGroup = mkOption {
      type = str;
      default = "Admin";
      description = "JWT group for admin access";
    };

    redis = {
      address = mkOption {
        type = str;
        default = "localhost:6379";
        description = "Redis server address";
      };
    };

    instances = mkOption {
      type = attrsOf (submodule {
        options = {
          port = mkOption {
            type = int;
            description = "Port to run BanterBus on";
          };

          domain = mkOption {
            type = str;
            description = "Domain for this instance";
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
          after = [ "network.target" "postgresql.service" "redis-main.service" ];
          requires = [ "postgresql.service" "redis-main.service" ];

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
              "BANTERBUS_REDIS_ADDRESS=${cfg.redis.address}"
              "BANTERBUS_JWKS_URL=${cfg.jwksUrl}"
              "BANTERBUS_JWT_ADMIN_GROUP=${cfg.adminGroup}"
              "BANTERBUS_WEBSERVER_PORT=${toString instanceCfg.port}"
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

