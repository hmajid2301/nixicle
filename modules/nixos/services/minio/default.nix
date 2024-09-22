{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.minio;
in {
  options.services.nixicle.minio = {
    enable = mkEnableOption "Enable the minio";
  };

  config = mkIf cfg.enable {
    users.users.minio.extraGroups = ["media"];

    services = {
      minio = {
        enable = true;
        listenAddress = ":9055";
        consoleAddress = ":9056";
        dataDir = ["/mnt/share/minio"];
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              minio.loadBalancer.servers = [
                {
                  url = "http://localhost:9056";
                }
              ];
            };

            routers = {
              minio = {
                entryPoints = ["websecure"];
                rule = "Host(`minio.homelab.haseebmajid.dev`)";
                service = "minio";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
