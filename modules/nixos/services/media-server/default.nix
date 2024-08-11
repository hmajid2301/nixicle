{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.media-server;
in {
  options.services.media-server = {
    enable = mkEnableOption "Enable the media server";
  };

  config = mkIf cfg.enable {
    services = {
      bazarr.enable = true;
      lidarr.enable = true;
      radarr.enable = true;
      prowlarr.enable = true;
      jellyseerr.enable = true;
      jellyfin.enable = true;
      sonarr.enable = true;

      traefik = {
        dynamicConfigOptions = {
          http = {
            services.jellyfin.loadBalancer.servers = [
              {
                url = "http://localhost:8096";
              }
            ];

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
