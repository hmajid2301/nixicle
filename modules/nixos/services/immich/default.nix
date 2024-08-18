{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.immich;

  # Taken from this gist: https://gist.github.com/mfenniak/c6f6b1cde07fc33df4d925e13f7d5afa
  immichRoot = "/mnt/share/haseeb/homelab/immich";
  immichPhotos = "${immichRoot}/photos";
  immichAppdataRoot = "${immichRoot}/appdata";
  immichVersion = "release";

  postgresRoot = "${immichAppdataRoot}/pgsql";
in {
  options.services.nixicle.immich = {
    enable = mkEnableOption "Enable the immich service";
  };

  config = mkIf cfg.enable {
    sops.secrets.immich_postgres_env = {
      sopsFile = ../secrets.yaml;
    };

    services.traefik = {
      dynamicConfigOptions = {
        http = {
          services = {
            photos.loadBalancer.servers = [
              {
                url = "http://localhost:2283";
              }
            ];
          };

          routers = {
            photos = {
              entryPoints = ["websecure"];
              rule = "Host(`photos.bare.homelab.haseebmajid.dev`)";
              service = "photos";
              tls.certResolver = "letsencrypt";
            };
          };
        };
      };
    };

    virtualisation.oci-containers.containers = {
      immich_server = {
        image = "ghcr.io/immich-app/immich-server:${immichVersion}";
        ports = ["127.0.0.1:2283:3001"];
        extraOptions = [
          "--pull=newer"
          # Force DNS resolution to only be the podman dnsname name server; by default podman provides a resolv.conf
          # that includes both this server and the upstream system server, causing resolutions of other pod names
          # to be inconsistent.
          "--dns=10.88.0.1"
        ];
        cmd = ["start.sh" "immich"];
        environmentFiles = [
          "${config.sops.secrets.immich_postgres_env.path}"
        ];
        environment = {
          IMMICH_VERSION = immichVersion;
          DB_HOSTNAME = "immich_postgres";
          REDIS_HOSTNAME = "immich_redis";
        };
        volumes = [
          "${immichPhotos}:/usr/src/app/upload"
          "/etc/localtime:/etc/localtime:ro"
        ];
      };

      immich_microservices = {
        image = "ghcr.io/immich-app/immich-server:${immichVersion}";
        extraOptions = [
          "--pull=newer"
          # Force DNS resolution to only be the podman dnsname name server; by default podman provides a resolv.conf
          # that includes both this server and the upstream system server, causing resolutions of other pod names
          # to be inconsistent.
          "--dns=10.88.0.1"
        ];
        cmd = ["start.sh" "microservices"];
        environmentFiles = [
          "${config.sops.secrets.immich_postgres_env.path}"
        ];
        environment = {
          IMMICH_VERSION = immichVersion;
          DB_HOSTNAME = "immich_postgres";
          REDIS_HOSTNAME = "immich_redis";
        };
        volumes = [
          "${immichPhotos}:/usr/src/app/upload"
          "/etc/localtime:/etc/localtime:ro"
        ];
      };

      immich_machine_learning = {
        image = "ghcr.io/immich-app/immich-machine-learning:${immichVersion}";
        extraOptions = ["--pull=newer"];
        environment = {
          IMMICH_VERSION = immichVersion;
        };
        volumes = [
          "${immichAppdataRoot}/model-cache:/cache"
        ];
      };

      immich_redis = {
        image = "redis:6.2-alpine@sha256:80cc8518800438c684a53ed829c621c94afd1087aaeb59b0d4343ed3e7bcf6c5";
      };

      # TODO: should this be a central service everything can connect to?
      immich_postgres = {
        image = "tensorchord/pgvecto-rs:pg14-v0.1.11";
        environmentFiles = [
          "${config.sops.secrets.immich_postgres_env.path}"
        ];
        volumes = [
          "${postgresRoot}:/var/lib/postgresql/data"
        ];
      };
    };
  };
}
