{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.hortusfox;

  # Container network name
  networkName = "hortusfox-network";

  # Database credentials - will be read from environment file
  dbName = "hortusfox";
  dbUser = "hortusfox";
in
{
  options.services.nixicle.hortusfox = with types; {
    enable = mkBoolOpt false "Enable the hortusfox plant management service";
    domain = mkOpt str "plants.haseebmajid.dev" "Domain for hortusfox";
    port = mkOpt int 25780 "Port for hortusfox web interface";
    dataDir = mkOpt str "/var/lib/hortusfox" "Directory to store hortusfox data";

    admin = {
      email = mkOpt str "hello@haseebmajid.dev" "Admin email for hortusfox";
    };

    database = {
      host = mkOpt str "hortusfox-db" "Database host (container name)";
      port = mkOpt int 3306 "Database port";
    };

    authentik = {
      enable = mkBoolOpt true "Enable Authentik forward auth";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      virtualisation = {
        containers.enable = true;
        podman = {
          enable = true;
          dockerSocket.enable = false;
          dockerCompat = false;
          defaultNetwork.settings.dns_enabled = true;
        };
      };

      systemd.services.podman-network-hortusfox = {
        description = "Create podman network for hortusfox";
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.podman}/bin/podman network create ${networkName} || true";
          ExecStop = "${pkgs.podman}/bin/podman network rm ${networkName} || true";
        };
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir}/images 0750 1000 1000 -"
        "d ${cfg.dataDir}/logs 0750 1000 1000 -"
        "d ${cfg.dataDir}/backup 0750 1000 1000 -"
        "d ${cfg.dataDir}/themes 0750 1000 1000 -"
        "d ${cfg.dataDir}/migrations 0750 1000 1000 -"
        "d ${cfg.dataDir}/db 0750 1000 1000 -"
      ];

      sops.secrets.hortusfox_env = {
        sopsFile = ../secrets.yaml;
      };

      virtualisation.oci-containers.containers.hortusfox-db = {
        image = "mariadb:11";
        autoStart = true;
        environment = {
          MARIADB_DATABASE = dbName;
          MARIADB_USER = dbUser;
          MARIADB_ROOT_HOST = "%";
        };
        environmentFiles = [ config.sops.secrets.hortusfox_env.path ];
        volumes = [
          "${cfg.dataDir}/db:/var/lib/mysql"
        ];
        extraOptions = [
          "--network=${networkName}"
        ];
      };

      # HortusFox app container
      virtualisation.oci-containers.containers.hortusfox = {
        image = "ghcr.io/danielbrendel/hortusfox-web:latest";
        autoStart = true;
        ports = [ "127.0.0.1:${toString cfg.port}:80" ];
        environment = {
          APP_ADMIN_EMAIL = cfg.admin.email;
          APP_TIMEZONE = "UTC";
          DB_HOST = cfg.database.host;
          DB_PORT = toString cfg.database.port;
          DB_DATABASE = dbName;
          DB_USERNAME = dbUser;
          DB_CHARSET = "utf8mb4";
          PROXY_ENABLE = if cfg.authentik.enable then "true" else "false";
          PROXY_HEADER_EMAIL = "X-authentik-email";
          PROXY_HEADER_USERNAME = "X-authentik-username";
          PROXY_AUTO_SIGNUP = "true";
          PROXY_WHITELIST = "";
          PROXY_HIDE_LOGOUT = if cfg.authentik.enable then "true" else "false";
          PROXY_OVERWRITE_VALUES = "true";
        };
        environmentFiles = [ config.sops.secrets.hortusfox_env.path ];
        volumes = [
          "${cfg.dataDir}/images:/var/www/html/public/img"
          "${cfg.dataDir}/logs:/var/www/html/app/logs"
          "${cfg.dataDir}/backup:/var/www/html/public/backup"
          "${cfg.dataDir}/themes:/var/www/html/public/themes"
          "${cfg.dataDir}/migrations:/var/www/html/app/migrations"
        ];
        extraOptions = [
          "--network=${networkName}"
        ];
      };

      # Ensure containers start after network is ready
      systemd.services.podman-hortusfox-db.after = [
        "podman-network-hortusfox.service"
        "network-online.target"
      ];
      systemd.services.podman-hortusfox-db.requires = [ "podman-network-hortusfox.service" ];

      systemd.services.podman-hortusfox = {
        after = [
          "podman-hortusfox-db.service"
          "network-online.target"
        ];
        requires = [ "podman-hortusfox-db.service" ];
        wantedBy = [ "multi-user.target" ];
      };

      environment.persistence = mkIf config.system.impermanence.enable {
        "/persist" = {
          directories = [
            {
              directory = cfg.dataDir;
              user = "1000";
              group = "1000";
              mode = "0750";
            }
          ];
        };
      };
    }

    (mkIf config.services.traefik.enable {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
        name = "hortusfox";
        port = cfg.port;
      };
    })
    {
      services.cloudflared.tunnels = mkIf config.services.nixicle.cloudflare.enable {
        ${config.services.nixicle.cloudflare.tunnelId}.ingress = {
          ${cfg.domain} = "http://localhost:${toString cfg.port}";
        };
      };
    }
  ]);
}
