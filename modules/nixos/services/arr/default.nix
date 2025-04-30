{ config, lib, ... }:
with lib;
let cfg = config.services.arr;
in {
  options.services.arr = { enable = mkEnableOption "Enable the arr"; };

  config = mkIf cfg.enable {
    users.groups.media = { };

    systemd.tmpfiles.rules = [
      "d /mnt/n1/media 0775 root media -"
      "d /mnt/n1/media/Shows 0775 root media -"
      "d /mnt/n1/media/Movies 0775 root media -"
      "d /mnt/n1/media/Music 0775 root media -"
      "d /mnt/n1/media/Books 0775 root media -"
    ];

    services = {
      bazarr = {
        enable = true;
        group = "media";
      };
      lidarr = {
        enable = true;
        group = "media";
      };
      readarr = {
        enable = true;
        group = "media";
      };
      radarr = {
        enable = true;
        group = "media";
      };
      prowlarr.enable = true;
      sonarr = {
        enable = true;
        group = "media";
      };
      # flaresolverr = {
      #   enable = true;
      #   port = 8191;
      #   openFirewall = true;
      # };

      jellyseerr.enable = true;

      cloudflared = {
        enable = true;
        tunnels = {
          "ec0b6af0-a823-4616-a08b-b871fd2c7f58" = {
            ingress = {
              "jellyseerr.haseebmajid.dev" = "http://localhost:5055";
            };
          };
        };
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              bazarr.loadBalancer.servers =
                [{ url = "http://localhost:6767"; }];
              readarr.loadBalancer.servers =
                [{ url = "http://localhost:8787"; }];
              lidarr.loadBalancer.servers =
                [{ url = "http://localhost:8686"; }];
              radarr.loadBalancer.servers =
                [{ url = "http://localhost:7878"; }];
              prowlarr.loadBalancer.servers =
                [{ url = "http://localhost:9696"; }];
              sonarr.loadBalancer.servers =
                [{ url = "http://localhost:8989"; }];
              jellyseerr.loadBalancer.servers =
                [{ url = "http://localhost:5055"; }];
              jellyfin.loadBalancer.servers =
                [{ url = "http://localhost:8096"; }];
            };

            routers = {
              bazarr = {
                entryPoints = [ "websecure" ];
                rule = "Host(`bazarr.homelab.haseebmajid.dev`)";
                service = "bazarr";
                tls.certResolver = "letsencrypt";
                middlewares = [ "authentik" ];
              };
              readarr = {
                entryPoints = [ "websecure" ];
                rule = "Host(`readarr.homelab.haseebmajid.dev`)";
                service = "readarr";
                tls.certResolver = "letsencrypt";
                middlewares = [ "authentik" ];
              };
              lidarr = {
                entryPoints = [ "websecure" ];
                rule = "Host(`lidarr.homelab.haseebmajid.dev`)";
                service = "lidarr";
                tls.certResolver = "letsencrypt";
                middlewares = [ "authentik" ];
              };
              radarr = {
                entryPoints = [ "websecure" ];
                rule = "Host(`radarr.homelab.haseebmajid.dev`)";
                service = "radarr";
                tls.certResolver = "letsencrypt";
                middlewares = [ "authentik" ];
              };
              prowlarr = {
                entryPoints = [ "websecure" ];
                rule = "Host(`prowlarr.homelab.haseebmajid.dev`)";
                service = "prowlarr";
                tls.certResolver = "letsencrypt";
                middlewares = [ "authentik" ];
              };
              sonarr = {
                entryPoints = [ "websecure" ];
                rule = "Host(`sonarr.homelab.haseebmajid.dev`)";
                service = "sonarr";
                tls.certResolver = "letsencrypt";
                middlewares = [ "authentik" ];
              };
              jellyseerr = {
                entryPoints = [ "websecure" ];
                rule = "Host(`jellyseerr.homelab.haseebmajid.dev`)";
                service = "jellyseerr";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
