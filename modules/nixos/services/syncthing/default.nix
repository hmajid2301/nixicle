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
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              syncthing.loadBalancer.servers = [
                {
                  url = "http://localhost:22000";
                }
              ];
            };

            routers = {
              syncthing = {
                entryPoints = ["websecure"];
                rule = "Host(`syncthing.bare.homelab.haseebmajid.dev`)";
                service = "syncthing";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
