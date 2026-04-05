{ den, inputs, ... }:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
  instances = {
    dev = { port = 8084; domain = "dev.banterbus.games"; };
    prod = { port = 8083; domain = "banterbus.games"; };
  };
  jwksUrl = "https://authentik.haseebmajid.dev/application/o/budibase/.well-known/openid-configuration";
  adminGroup = "Admin";
  redisAddress = "localhost:6379";
in
{
  flake-file.inputs.banterbus = {
    url = "gitlab:hmajid2301/banterbus";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.banterbus = {
    nixos = { config, pkgs, lib, ... }: {
      services.postgresql = {
        ensureDatabases = lib.mapAttrsToList (name: _: "banterbus_${name}") instances;
        ensureUsers = lib.mapAttrsToList (name: _: {
          name = "banterbus_${name}";
          ensureDBOwnership = true;
        }) instances;
      };

      users.users = lib.mapAttrs' (name: _: lib.nameValuePair "banterbus_${name}" {
        isSystemUser = true;
        group = "banterbus_${name}";
      }) instances;

      users.groups = lib.mapAttrs' (name: _: lib.nameValuePair "banterbus_${name}" { }) instances;

      systemd.services = lib.mapAttrs' (name: instanceCfg:
        let banterbus = inputs.banterbus.packages.${pkgs.stdenv.hostPlatform.system}.default;
        in lib.nameValuePair "banterbus_${name}" {
          description = "BanterBus ${name} trivia game service";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" "postgresql.service" "redis-main.service" ];
          requires = [ "postgresql.service" "redis-main.service" ];
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
              "BANTERBUS_WEBSERVER_PORT=${toString instanceCfg.port}"
            ];
            PrivateTmp = true;
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
          };
        }
      ) instances;

      networking.firewall.allowedTCPPorts = lib.mapAttrsToList (_: i: i.port) instances;

      services.cloudflared.tunnels.${tunnelId}.ingress =
        lib.mapAttrs' (_: i: lib.nameValuePair i.domain "http://localhost:${toString i.port}") instances;
    };
  };
}
