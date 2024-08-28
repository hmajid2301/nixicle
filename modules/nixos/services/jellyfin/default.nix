{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.jellyfin;
in {
  options.services.nixicle.jellyfin = {
    enable = mkEnableOption "Enable jellyfin service";
  };

  config = mkIf cfg.enable {
    services = {
      jellyfin.enable = true;

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              jellyfin.loadBalancer.servers = [
                {
                  url = "http://localhost:8096";
                }
              ];
            };

            routers = {
              jellyfin = {
                entryPoints = ["websecure"];
                rule = "Host(`jellyfin.bare.homelab.haseebmajid.dev`)";
                service = "jellyfin";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
