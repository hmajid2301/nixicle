{ config, lib, ... }:
with lib;
let cfg = config.services.arr;
in {
  options.services.arr = { enable = mkEnableOption "Enable the arr"; };

  config = mkIf cfg.enable (mkMerge [
    {
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


      };
    }

    # Traefik reverse proxy configuration
    {
      services.traefik.dynamicConfigOptions.http = mkMerge [
        # Bazarr
        (lib.nixicle.mkAuthenticatedTraefikService {
          name = "bazarr";
          port = 6767;
        })

        # Readarr
        (lib.nixicle.mkAuthenticatedTraefikService {
          name = "readarr";
          port = 8787;
        })

        # Lidarr
        (lib.nixicle.mkAuthenticatedTraefikService {
          name = "lidarr";
          port = 8686;
        })

        # Radarr
        (lib.nixicle.mkAuthenticatedTraefikService {
          name = "radarr";
          port = 7878;
        })

        # Prowlarr
        (lib.nixicle.mkAuthenticatedTraefikService {
          name = "prowlarr";
          port = 9696;
        })

        # Sonarr
        (lib.nixicle.mkAuthenticatedTraefikService {
          name = "sonarr";
          port = 8989;
        })

        # Jellyseerr
        (lib.nixicle.mkTraefikService {
          name = "jellyseerr";
          port = 5055;
        })
      ];
    }

    {
      services.cloudflared.tunnels = mkIf config.services.nixicle.cloudflare.enable {
        ${config.services.nixicle.cloudflare.tunnelId}.ingress = {
          "jellyseerr.haseebmajid.dev" = "http://localhost:5055";
        };
      };
    }
  ]);
}
