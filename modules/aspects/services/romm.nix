{ ... }:
let
  dataDir = "/data/romm";
  romsDir = "/data/media/roms";
  port = 8082;
  networkName = "romm-network";
  dbName = "romm";
  dbUser = "romm-user";
in
{
  den.aspects.romm = {
    includes = [ ];

    nixos =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      {
        sops.secrets.romm_env = { };
        virtualisation.oci-containers.backend = "docker";

        systemd = {
          services = {
            docker-network-romm = {
              description = "Create docker network for romm";
              after = [ "network-online.target" ];
              wants = [ "network-online.target" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = "${pkgs.docker}/bin/docker network create ${networkName} 2>/dev/null || true";
                ExecStop = "${pkgs.docker}/bin/docker network rm ${networkName} 2>/dev/null || true";
              };
            };
            docker-romm-db = {
              after = [
                "docker-network-romm.service"
                "network-online.target"
              ];
              requires = [ "docker-network-romm.service" ];
            };
            docker-romm = {
              after = [
                "docker-romm-db.service"
                "network-online.target"
              ];
              requires = [ "docker-romm-db.service" ];
              wantedBy = [ "multi-user.target" ];
            };
          };
          tmpfiles.rules = [
            "d ${dataDir} 0750 root root - -"
            "d ${dataDir}/db 0750 root root - -"
            "d ${dataDir}/config 0750 root root - -"
            "d ${dataDir}/resources 0750 root root - -"
            "d ${dataDir}/assets 0750 root root - -"
            "d ${dataDir}/redis 0750 root root - -"
            "d ${romsDir} 0775 root media - -"
          ];
        };

        virtualisation.oci-containers.containers = {
          romm-db = {
            image = "mariadb:11";
            autoStart = true;
            environment = {
              MARIADB_DATABASE = dbName;
              MARIADB_USER = dbUser;
            };
            environmentFiles = [ config.sops.secrets.romm_env.path ];
            volumes = [ "${dataDir}/db:/var/lib/mysql" ];
            extraOptions = [ "--network=${networkName}" ];
          };

          romm = {
            image = "rommapp/romm:latest";
            autoStart = true;
            ports = [ "127.0.0.1:${toString port}:8080" ];
            environment = {
              DB_HOST = "romm-db";
              DB_PORT = "3306";
              DB_NAME = dbName;
              DB_USER = dbUser;
            };
            environmentFiles = [ config.sops.secrets.romm_env.path ];
            volumes = [
              "${dataDir}/config:/romm/config"
              "${dataDir}/resources:/romm/resources"
              "${dataDir}/assets:/romm/assets"
              "${dataDir}/redis:/redis-data"
              "${romsDir}:/romm/library/roms"
            ];
            extraOptions = [ "--network=${networkName}" ];
          };
        };

        services.traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
          name = "romm";
          inherit port;
        };
      };
  };
}
