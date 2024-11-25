{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.immich;
in {
  options.services.nixicle.immich = {
    enable = mkEnableOption "Enable the immich photo service";
  };

  config = mkIf cfg.enable {
    services = {
      immich = {
        enable = true;
        host = "0.0.0.0";
        group = "media";
        mediaLocation = "/mnt/share/immich";
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              immich.loadBalancer.servers = [
                {
                  url = "http://localhost:2283";
                }
              ];
            };

            routers = {
              immich = {
                entryPoints = ["websecure"];
                rule = "Host(`immich.homelab.haseebmajid.dev`)";
                service = "immich";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
