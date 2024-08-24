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
    users.groups.media = {};

    services = {
      bazarr.enable = true;
      bazarr.group = "media";
      lidarr.enable = true;
      lidarr.group = "media";
      readarr.enable = true;
      readarr.group = "media";
      radarr.enable = true;
      radarr.group = "media";
      sonarr.enable = true;
      sonarr.group = "media";

      flaresolverr.enable = true;
      flaresolverr.openFirewall = true;

      prowlarr.enable = true;

      jellyseerr.enable = true;
      jellyfin.enable = true;

      deluge = {
        enable = true;
        web.enable = true;
        group = "media";
      };

      audiobookshelf = {
        enable = true;
        port = 8555;
        group = "media";
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              jellyfin.loadBalancer.servers = [
                {
                  url = "http://localhost:8096";
                }
              ];
              bazarr.loadBalancer.servers = [
                {
                  url = "http://localhost:6767";
                }
              ];
              readarr.loadBalancer.servers = [
                {
                  url = "http://localhost:8787";
                }
              ];
              lidarr.loadBalancer.servers = [
                {
                  url = "http://localhost:8686";
                }
              ];
              radarr.loadBalancer.servers = [
                {
                  url = "http://localhost:7878";
                }
              ];
              prowlarr.loadBalancer.servers = [
                {
                  url = "http://localhost:9696";
                }
              ];
              jellyseerr.loadBalancer.servers = [
                {
                  url = "http://localhost:5055";
                }
              ];
              sonarr.loadBalancer.servers = [
                {
                  url = "http://localhost:8989";
                }
              ];
              deluge.loadBalancer.servers = [
                {
                  url = "http://localhost:8112";
                }
              ];
              audiobookshelf.loadBalancer.servers = [
                {
                  url = "http://localhost:8555";
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
              bazarr = {
                entryPoints = ["websecure"];
                rule = "Host(`bazarr.bare.homelab.haseebmajid.dev`)";
                service = "bazarr";
                tls.certResolver = "letsencrypt";
                middlewares = ["authentik"];
              };
              readarr = {
                entryPoints = ["websecure"];
                rule = "Host(`readarr.bare.homelab.haseebmajid.dev`)";
                service = "readarr";
                tls.certResolver = "letsencrypt";
                middlewares = ["authentik"];
              };
              lidarr = {
                entryPoints = ["websecure"];
                rule = "Host(`lidarr.bare.homelab.haseebmajid.dev`)";
                service = "lidarr";
                tls.certResolver = "letsencrypt";
                middlewares = ["authentik"];
              };
              radarr = {
                entryPoints = ["websecure"];
                rule = "Host(`radarr.bare.homelab.haseebmajid.dev`)";
                service = "radarr";
                tls.certResolver = "letsencrypt";
                middlewares = ["authentik"];
              };
              prowlarr = {
                entryPoints = ["websecure"];
                rule = "Host(`prowlarr.bare.homelab.haseebmajid.dev`)";
                service = "prowlarr";
                tls.certResolver = "letsencrypt";
                middlewares = ["authentik"];
              };
              jellyseerr = {
                entryPoints = ["websecure"];
                rule = "Host(`jellyseerr.bare.homelab.haseebmajid.dev`)";
                service = "jellyseerr";
                tls.certResolver = "letsencrypt";
              };
              sonarr = {
                entryPoints = ["websecure"];
                rule = "Host(`sonarr.bare.homelab.haseebmajid.dev`)";
                service = "sonarr";
                tls.certResolver = "letsencrypt";
                middlewares = ["authentik"];
              };
              deluge = {
                entryPoints = ["websecure"];
                rule = "Host(`deluge.bare.homelab.haseebmajid.dev`)";
                service = "deluge";
                tls.certResolver = "letsencrypt";
              };
              audiobookshelf = {
                entryPoints = ["websecure"];
                rule = "Host(`audiobookshelf.bare.homelab.haseebmajid.dev`)";
                service = "audiobookshelf";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
