{ config, lib, ... }:
with lib;
with lib.nixicle;
let cfg = config.services.nixicle.immich;
in {
  options.services.nixicle.immich = {
    enable = mkEnableOption "Enable the immich photo service";
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [ "d /mnt/n2/immich 0775 immich media -" ];

    services = {
      immich = {
        enable = true;
        host = "0.0.0.0";
        mediaLocation = "/mnt/n2/immich";
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              immich.loadBalancer.servers =
                [{ url = "http://localhost:2283"; }];
            };

            routers = {
              immich = {
                entryPoints = [ "websecure" ];
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
