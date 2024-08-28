{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.syncthing;
in {
  options.services.nixicle.syncthing = {
    enable = mkEnableOption "Enable the syncthing service";
  };

  config = mkIf cfg.enable {
    services = {
      syncthing = {
        enable = true;
        guiAddress = "0.0.0.0:8384";
        dataDir = "/mnt/share/haseeb/homelab/syncthing";
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              syncthing.loadBalancer.servers = [
                {
                  url = "http://localhost:8384";
                }
              ];
            };

            routers = {
              syncthing = {
                entryPoints = ["websecure"];
                rule = "Host(`syncthing.bare.homelab.haseebmajid.dev`)";
                service = "syncthing";
                tls.certResolver = "letsencrypt";
                middlewares = ["authentik"];
              };
            };
          };
        };
      };
    };
  };
}
