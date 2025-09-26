{ config, lib, ... }:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.immich;
in
{
  options.services.nixicle.immich = {
    enable = mkEnableOption "Enable the immich photo service";
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [ "d /mnt/n1/immich 0775 immich media -" ];

    services = {
      immich = {
        enable = true;
        host = "0.0.0.0";
        mediaLocation = "/mnt/n1/immich";
        database.enableVectors = false;
        database.enableVectorChord = true;
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              immich.loadBalancer.servers = [ { url = "http://localhost:2283"; } ];
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
