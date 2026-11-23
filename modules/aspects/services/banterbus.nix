{ inputs, ... }:
let
  instances = {
    dev = {
      port = 8084;
      domain = "dev.banterbus.haseebmajid.dev";
    };
    prod = {
      port = 8083;
      domain = "banterbus.haseebmajid.dev";
    };
  };
  jwksUrl = "https://id.haseebmajid.dev/.well-known/jwks.json";
  jwtIssuer = "https://id.haseebmajid.dev";
  quizAudience = "banter-quiz";
  adminGroup = "Admin";
  redisAddress = "127.0.0.1:6380";
in
{
  flake-file.inputs.banterbus = {
    url = "gitlab:hmajid2301/banterbus";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.banterbus = {
    nixos =
      {
        pkgs,
        lib,
        ...
      }:
      let
        traefikConfigs = lib.mapAttrsToList (name: instanceCfg: {
          services."banterbus-${name}".loadBalancer.servers = [
            {
              url = "http://localhost:${toString instanceCfg.port}";
            }
          ];
          routers."banterbus-${name}" = {
            entryPoints = [ "websecure" ];
            rule = "Host(`${instanceCfg.domain}`)";
            service = "banterbus-${name}";
            tls.certResolver = "letsencrypt";
          };
        }) instances;
      in
      {
        services.postgresql = {
          ensureDatabases = lib.mapAttrsToList (name: _: "banterbus_${name}") instances;
          ensureUsers = lib.mapAttrsToList (name: _: {
            name = "banterbus_${name}";
            ensureDBOwnership = true;
          }) instances;
        };

        users.users = lib.mapAttrs' (
          name: _:
          lib.nameValuePair "banterbus_${name}" {
            isSystemUser = true;
            group = "banterbus_${name}";
          }
        ) instances;

        users.groups = lib.mapAttrs' (name: _: lib.nameValuePair "banterbus_${name}" { }) instances;

        systemd.services = lib.mapAttrs' (
          name: instanceCfg:
          let
            banterbus =
              inputs.banterbus.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
                (old: {
                  postInstall = (old.postInstall or "") + ''
                    mkdir -p "$out/migrations"
                    cp ${inputs.banterbus}/internal/store/db/sqlc/migrations/*.sql "$out/migrations/"
                  '';
                });
          in
          lib.nameValuePair "banterbus_${name}" {
            description = "BanterBus ${name} trivia game service";
            wantedBy = [ "multi-user.target" ];
            after = [
              "network.target"
              "postgresql.service"
              "redis-main.service"
            ];
            requires = [
              "postgresql.service"
              "redis-main.service"
            ];
            preStart = ''
              ${pkgs.goose}/bin/goose -dir "${banterbus}/migrations" postgres \
                "host=$BANTERBUS_DB_HOST port=$BANTERBUS_DB_PORT user=$BANTERBUS_DB_USERNAME dbname=$BANTERBUS_DB_NAME sslmode=disable" \
                up
            '';
            serviceConfig = {
              Type = "simple";
              User = "banterbus_${name}";
              Group = "banterbus_${name}";
              ExecStart = "${banterbus}/bin/banterbus";
              Restart = "on-failure";
              RestartSec = "5s";
              Environment = [
                "BANTERBUS_DB_USERNAME=banterbus_${name}"
                "BANTERBUS_DB_HOST=/run/postgresql"
                "BANTERBUS_DB_PORT=5432"
                "BANTERBUS_DB_NAME=banterbus_${name}"
                "BANTERBUS_REDIS_ADDRESS=${redisAddress}"
                "BANTERBUS_JWKS_URL=${jwksUrl}"
                "BANTERBUS_JWT_ADMIN_GROUP=${adminGroup}"
                "BANTERBUS_JWT_ISSUER=${jwtIssuer}"
                "BANTERBUS_PUBLIC_URL=https://${instanceCfg.domain}"
                "BANTERBUS_QUIZ_AUDIENCE=${quizAudience}"
                "BANTERBUS_WEBSERVER_PORT=${toString instanceCfg.port}"
              ];
              PrivateTmp = true;
              PrivateDevices = true;
              NoNewPrivileges = true;
              ProtectSystem = "strict";
              ProtectHome = true;
              ProtectKernelLogs = true;
              ProtectKernelTunables = true;
              ProtectControlGroups = true;
              ProtectKernelModules = true;
              RestrictSUIDSGID = true;
              LockPersonality = true;
              RestrictNamespaces = true;
              RestrictRealtime = true;
              SystemCallArchitectures = "native";
            };
          }
        ) instances;

        services.traefik.dynamicConfigOptions.http = lib.mkMerge traefikConfigs;
      };
  };
}
