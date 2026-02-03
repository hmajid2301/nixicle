{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.nixflix;
in
{
  options.services.nixicle.nixflix = {
    enable = mkEnableOption "nixflix media server";

    mediaDir = mkOption {
      type = types.path;
      default = "/mnt/homelab/homelab/media";
      description = "Path to media directory";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      users.groups.media = { };

      sops.secrets = {
        "sonarr/api_key" = {
          sopsFile = ../secrets.yaml;
          owner = "sonarr";
        };
        "sonarr/password" = {
          sopsFile = ../secrets.yaml;
          owner = "sonarr";
        };
        "radarr/api_key" = {
          sopsFile = ../secrets.yaml;
          owner = "radarr";
        };
        "radarr/password" = {
          sopsFile = ../secrets.yaml;
          owner = "radarr";
        };
        "lidarr/api_key" = {
          sopsFile = ../secrets.yaml;
          owner = "lidarr";
        };
        "lidarr/password" = {
          sopsFile = ../secrets.yaml;
          owner = "lidarr";
        };
        "prowlarr/api_key" = {
          sopsFile = ../secrets.yaml;
          owner = "prowlarr";
        };
        "prowlarr/password" = {
          sopsFile = ../secrets.yaml;
          owner = "prowlarr";
        };
        "jellyseerr/api_key" = {
          sopsFile = ../secrets.yaml;
          owner = "jellyseerr";
        };
        "jellyfin/admin_password" = {
          sopsFile = ../secrets.yaml;
          owner = "jellyfin";
        };
      };

      systemd.tmpfiles.rules = [
        # "d ${cfg.mediaDir} 0775 root media -"
        # "d ${cfg.mediaDir}/tv 0775 root media -"
        # "d ${cfg.mediaDir}/movies 0775 root media -"
        # "d ${cfg.mediaDir}/music 0775 root media -"
        # "d ${cfg.mediaDir}/books 0775 root media -"
        "d /run/jellyfin 0755 jellyfin jellyfin -"
      ];

      systemd.services.jellyfin-libraries = {
        serviceConfig = {
          User = "jellyfin";
          Group = "media";
        };
      };

      systemd.services.jellyseerr-setup = {
        enable = false;
      };

      nixflix = {
        enable = true;
        mediaDir = cfg.mediaDir;
        mediaUsers = [ "haseeb" ];
        postgres.enable = false;

        sonarr = {
          enable = true;
          config = {
            apiKey = {
              _secret = config.sops.secrets."sonarr/api_key".path;
            };
            hostConfig.password = {
              _secret = config.sops.secrets."sonarr/password".path;
            };
          };
        };
        radarr = {
          enable = true;
          config = {
            apiKey = {
              _secret = config.sops.secrets."radarr/api_key".path;
            };
            hostConfig.password = {
              _secret = config.sops.secrets."radarr/password".path;
            };
          };
        };
        prowlarr = {
          enable = true;
          config = {
            apiKey = {
              _secret = config.sops.secrets."prowlarr/api_key".path;
            };
            hostConfig.password = {
              _secret = config.sops.secrets."prowlarr/password".path;
            };
          };
        };
        lidarr = {
          enable = true;
          config = {
            apiKey = {
              _secret = config.sops.secrets."lidarr/api_key".path;
            };
            hostConfig.password = {
              _secret = config.sops.secrets."lidarr/password".path;
            };
          };
        };
        jellyfin = {
          enable = true;
          users.admin = {
            mutable = false;
            policy.isAdministrator = true;
            password = {
              _secret = config.sops.secrets."jellyfin/admin_password".path;
            };
          };
          libraries = {
            Movies = {
              collectionType = "movies";
              paths = [ "${cfg.mediaDir}/movies" ];
            };
            Shows = {
              collectionType = "tvshows";
              paths = [ "${cfg.mediaDir}/tv" ];
            };
            Music = {
              collectionType = "music";
              paths = [ "${cfg.mediaDir}/music" ];
            };
            Books = {
              collectionType = "books";
              paths = [ "${cfg.mediaDir}/books" ];
            };
          };
        };
        jellyseerr = {
          enable = true;
          apiKey = {
            _secret = config.sops.secrets."jellyseerr/api_key".path;
          };
          # jellyfin = {
          #   enableAllLibraries = true;
          #   hostname = "127.0.0.1";
          #   port = 8096;
          #   useSsl = false;
          # };
          # sonarr.default = {
          #   hostname = "127.0.0.1";
          #   port = 8989;
          #   useSsl = false;
          #   apiKey = {
          #     _secret = config.sops.secrets."sonarr/api_key".path;
          #   };
          #   activeDirectory = "${cfg.mediaDir}/tv";
          #   enableSeasonFolders = true;
          #   isDefault = true;
          #   syncEnabled = true;
          # };
          # radarr.default = {
          #   hostname = "127.0.0.1";
          #   port = 7878;
          #   useSsl = false;
          #   apiKey = {
          #     _secret = config.sops.secrets."radarr/api_key".path;
          #   };
          #   activeDirectory = "${cfg.mediaDir}/movies";
          #   isDefault = true;
          #   syncEnabled = true;
          #   minimumAvailability = "released";
          # };
        };
        mullvad.enable = false;
      };

      systemd.services.jellyfin.environment = {
        LIBVA_DRIVER_NAME = "radeonsi"; # AMD GPU
      };

      services.jellyfin = {
        openFirewall = true;
        hardwareAcceleration = {
          enable = true;
          type = "vaapi";
          device = "/dev/dri/renderD128";
        };
      };

      users.users.jellyfin.extraGroups = [
        "render"
        "video"
        "media"
      ];

      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          libva-vdpau-driver
          libvdpau-va-gl
          rocmPackages.clr.icd
        ];
      };
    }

    {
      services.traefik.dynamicConfigOptions.http = mkMerge [
        (lib.nixicle.mkAuthenticatedTraefikService {
          name = "sonarr";
          port = 8989;
        })

        (lib.nixicle.mkAuthenticatedTraefikService {
          name = "radarr";
          port = 7878;
        })

        (lib.nixicle.mkAuthenticatedTraefikService {
          name = "prowlarr";
          port = 9696;
        })

        (lib.nixicle.mkAuthenticatedTraefikService {
          name = "lidarr";
          port = 8686;
        })

        (lib.nixicle.mkTraefikService {
          name = "jellyfin";
          port = 8096;
        })

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

    {
      environment.persistence."/persist" = mkIf config.system.impermanence.enable {
        directories = [
          {
            directory = "/var/lib/nixflix";
            user = "root";
            group = "media";
            mode = "0775";
          }
          {
            directory = "/var/lib/jellyfin";
            user = "jellyfin";
            group = "jellyfin";
            mode = "0750";
          }
        ];
      };
    }
  ]);
}
