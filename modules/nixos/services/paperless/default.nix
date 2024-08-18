{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.paperless;
in {
  options.services.nixicle.paperless = {
    enable = mkEnableOption "Enable the paperless service";
  };

  config = mkIf cfg.enable {
    services = {
      paperless = {
        enable = true;
        mediaDir = "/mnt/share/haseeb/homelab/paperless/media";
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              paperless.loadBalancer.servers = [
                {
                  url = "http://localhost:28981";
                }
              ];
            };

            routers = {
              paperless = {
                entryPoints = ["websecure"];
                rule = "Host(`paperless.bare.homelab.haseebmajid.dev`)";
                service = "paperless";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
