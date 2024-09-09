{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.deluge;
in {
  options.services.nixicle.deluge = {
    enable = mkEnableOption "Enable the deluge downloader";
  };

  config = mkIf cfg.enable {
    services = {
      deluge = {
        enable = true;
        web.enable = true;
        group = "media";
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              deluge.loadBalancer.servers = [
                {
                  url = "http://localhost:8112";
                }
              ];
            };

            routers = {
              deluge = {
                entryPoints = ["websecure"];
                rule = "Host(`deluge.homelab.haseebmajid.dev`)";
                service = "deluge";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
