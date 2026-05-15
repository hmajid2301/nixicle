{ ... }:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
  dataDir = "/var/lib/hortusfox";
  port = 25780;
  domain = "plants.haseebmajid.dev";
  networkName = "hortusfox-network";
  dbName = "hortusfox";
  dbUser = "hortusfox";
in
{
  den.aspects.hortusfox = {
    includes = [ ];
    persist.directories = [
      {
        directory = dataDir;
        user = "1000";
        group = "1000";
        mode = "0750";
      }
    ];
    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        sops.secrets.hortusfox_env.sopsFile = ../../../hosts/framebox/secrets.yaml;

        virtualisation.oci-containers.backend = "docker";

        systemd = {
          services = {
            docker-network-hortusfox = {
              description = "Create docker network for hortusfox";
              after = [ "network-online.target" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = "${pkgs.docker}/bin/docker network create ${networkName} 2>/dev/null || true";
                ExecStop = "${pkgs.docker}/bin/docker network rm ${networkName} 2>/dev/null || true";
              };
            };
            docker-hortusfox-db = {
              after = [
                "docker-network-hortusfox.service"
                "network-online.target"
              ];
              requires = [ "docker-network-hortusfox.service" ];
            };
            docker-hortusfox = {
              after = [
                "docker-hortusfox-db.service"
                "network-online.target"
              ];
              requires = [ "docker-hortusfox-db.service" ];
              wantedBy = [ "multi-user.target" ];
            };
          };
          tmpfiles.rules = [
            "d ${dataDir}/images 0750 1000 1000 -"
            "d ${dataDir}/logs 0750 1000 1000 -"
            "d ${dataDir}/backup 0750 1000 1000 -"
            "d ${dataDir}/themes 0750 1000 1000 -"
            "d ${dataDir}/migrations 0750 1000 1000 -"
            "d ${dataDir}/db 0750 1000 1000 -"
          ];
        };

        virtualisation.oci-containers.containers = {
          hortusfox-db = {
            image = "mariadb:11";
            autoStart = true;
            environment = {
              MARIADB_DATABASE = dbName;
              MARIADB_USER = dbUser;
              MARIADB_ROOT_HOST = "%";
            };
            environmentFiles = [ config.sops.secrets.hortusfox_env.path ];
            volumes = [ "${dataDir}/db:/var/lib/mysql" ];
            extraOptions = [ "--network=${networkName}" ];
          };

          hortusfox = {
            image = "ghcr.io/danielbrendel/hortusfox-web:latest";
            autoStart = true;
            ports = [ "127.0.0.1:${toString port}:80" ];
            environment = {
              APP_ADMIN_EMAIL = "hello@haseebmajid.dev";
              APP_TIMEZONE = "UTC";
              DB_HOST = "hortusfox-db";
              DB_PORT = "3306";
              DB_DATABASE = dbName;
              DB_USERNAME = dbUser;
              DB_CHARSET = "utf8mb4";
              PROXY_ENABLE = "true";
              PROXY_HEADER_EMAIL = "X-authentik-email";
              PROXY_HEADER_USERNAME = "X-authentik-username";
              PROXY_AUTO_SIGNUP = "true";
              PROXY_WHITELIST = "";
              PROXY_HIDE_LOGOUT = "true";
              PROXY_OVERWRITE_VALUES = "true";
            };
            environmentFiles = [ config.sops.secrets.hortusfox_env.path ];
            volumes = [
              "${dataDir}/images:/var/www/html/public/img"
              "${dataDir}/logs:/var/www/html/app/logs"
              "${dataDir}/backup:/var/www/html/public/backup"
              "${dataDir}/themes:/var/www/html/public/themes"
              "${dataDir}/migrations:/var/www/html/app/migrations"
            ];
            extraOptions = [ "--network=${networkName}" ];
          };
        };

        services = {
          traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
            name = "hortusfox";
            inherit port;
          };
          cloudflared.tunnels.${tunnelId}.ingress.${domain} = "http://localhost:${toString port}";
        };
      };
  };
}
