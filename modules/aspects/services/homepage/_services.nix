# Homepage service list.
#
# Public hrefs and widget internal URLs are derived from the Traefik routers/services
# declared by each service module. Services are only shown when the matching NixOS
# option is enabled on the host.
#
# The only values still pulled from /run/secrets/homepage_env are actual secrets:
#   HOMEPAGE_VAR_TANDOOR_API_KEY
#   HOMEPAGE_VAR_PAPRA_TOKEN
#   HOMEPAGE_VAR_PAPRA_ORGANIZATION_ID
#   HOMEPAGE_VAR_KARAKEEP_API_KEY
# HOMEPAGE_VAR_GRAFANA_USERNAME
# HOMEPAGE_VAR_GRAFANA_PASSWORD
#   HOMEPAGE_VAR_TAILSCALE_DEVICE_ID
#   HOMEPAGE_VAR_TAILSCALE_KEY
#
# Papra uses the generic customapi widget because it is not a built-in integration.
{ config, lib, ... }:
let
  l = import ./_lib.nix { inherit config lib; };
  iconSet = import ./_service-icons.nix { inherit lib; };
  inherit (iconSet) serviceIcons;
  inherit (l)
    publicUrl
    internalUrl
    hrefOr
    serviceEnabled
    unitEnabled
    mkHomepageService
    ;
in
lib.flatten [
  {
    external = lib.flatten [
      (mkHomepageService {
        name = "Tandoor";
        icon = serviceIcons.Tandoor;
        description = "recipe management";
        enable = serviceEnabled [
          "services"
          "tandoor-recipes"
          "enable"
        ];
        href = publicUrl "tandoor";
        widget = {
          type = "tandoor";
          url = internalUrl "tandoor";
          key = "{{HOMEPAGE_VAR_TANDOOR_API_KEY}}";
        };
      })

      (mkHomepageService {
        name = "Papra";
        icon = serviceIcons.Papra;
        description = "document organizer";
        enable = serviceEnabled [
          "services"
          "papra"
          "enable"
        ];
        href = publicUrl "papra";
        widget = {
          type = "customapi";
          url = "${internalUrl "papra"}/api/organizations/{{HOMEPAGE_VAR_PAPRA_ORGANIZATION_ID}}/documents/statistics";
          refreshInterval = 60000;
          headers = {
            Authorization = "Bearer {{HOMEPAGE_VAR_PAPRA_TOKEN}}";
          };
          mappings = [
            {
              field = "organizationStats.documentsCount";
              label = "Documents";
              format = "number";
            }
            {
              field = "organizationStats.documentsSize";
              label = "Size";
              format = "bytes";
            }
          ];
        };
      })

      (mkHomepageService {
        name = "Karakeep";
        icon = serviceIcons.Karakeep;
        description = "read-it-later";
        enable = serviceEnabled [
          "services"
          "karakeep"
          "enable"
        ];
        href = publicUrl "karakeep";
        widget = {
          type = "karakeep";
          url = internalUrl "karakeep";
          key = "{{HOMEPAGE_VAR_KARAKEEP_API_KEY}}";
        };
      })

      (mkHomepageService {
        name = "BanterBus";
        icon = serviceIcons.BanterBus;
        description = "quiz server";
        enable = unitEnabled "banterbus_prod";
        href = publicUrl "banterbus-prod";
      })

      (mkHomepageService {
        name = "Goroutinely";
        icon = serviceIcons.Goroutinely;
        description = "pixel tracker";
        enable = serviceEnabled [
          "services"
          "goroutinely"
          "enable"
        ];
        href = publicUrl "goroutinely";
      })

      (mkHomepageService {
        name = "LettuceGo";
        icon = serviceIcons.LettuceGo;
        description = "group decisions";
        enable = serviceEnabled [
          "services"
          "lettucego"
          "enable"
        ];
        href = publicUrl "lettucego";
      })

      (mkHomepageService {
        name = "Immich";
        icon = serviceIcons.Immich;
        description = "photo library";
        enable = serviceEnabled [
          "services"
          "immich"
          "enable"
        ];
        href = publicUrl "immich";
      })

      (mkHomepageService {
        name = "Jellyfin";
        icon = serviceIcons.Jellyfin;
        description = "media server";
        enable = publicUrl "jellyfin" != null;
        href = publicUrl "jellyfin";
      })

      (mkHomepageService {
        name = "Forgejo";
        icon = serviceIcons.Forgejo;
        description = "git forge";
        enable = serviceEnabled [
          "services"
          "forgejo"
          "enable"
        ];
        href = publicUrl "forgejo";
      })
    ];
  }

  {
    internal = lib.flatten [
      (mkHomepageService {
        name = "Traefik";
        icon = serviceIcons.Traefik;
        description = "reverse proxy";
        enable = serviceEnabled [
          "services"
          "traefik"
          "enable"
        ];
        href = "https://traefik.${lib.nixicle.domains.homelab}";
        widget = {
          type = "traefik";
          url = "http://127.0.0.1:8080";
        };
      })

      (mkHomepageService {
        name = "Pocket ID";
        icon = serviceIcons.PocketID;
        description = "identity provider";
        enable = serviceEnabled [
          "services"
          "pocket-id"
          "enable"
        ];
        href = publicUrl "pocket-id";
      })

      (mkHomepageService {
        name = "Sonarr";
        icon = serviceIcons.Sonarr;
        description = "TV series";
        enable = publicUrl "sonarr" != null;
        href = publicUrl "sonarr";
      })

      (mkHomepageService {
        name = "Sonarr Anime";
        icon = serviceIcons.SonarrAnime;
        description = "anime series";
        enable = publicUrl "sonarr-anime" != null;
        href = publicUrl "sonarr-anime";
      })

      (mkHomepageService {
        name = "Radarr";
        icon = serviceIcons.Radarr;
        description = "movies";
        enable = publicUrl "radarr" != null;
        href = publicUrl "radarr";
      })

      (mkHomepageService {
        name = "Prowlarr";
        icon = serviceIcons.Prowlarr;
        description = "indexer manager";
        enable = publicUrl "prowlarr" != null;
        href = publicUrl "prowlarr";
      })

      (mkHomepageService {
        name = "Seerr";
        icon = serviceIcons.Seerr;
        description = "media requests";
        enable = publicUrl "seerr" != null;
        href = publicUrl "seerr";
      })

      (mkHomepageService {
        name = "Maintainerr";
        icon = serviceIcons.Maintainerr;
        description = "media cleanup";
        enable = publicUrl "maintainerr" != null;
        href = publicUrl "maintainerr";
      })

      (mkHomepageService {
        name = "Home Assistant";
        icon = serviceIcons.HomeAssistant;
        description = "smart home";
        enable = serviceEnabled [
          "services"
          "home-assistant"
          "enable"
        ];
        href = publicUrl "homeAssistant";
      })
    ];
  }

  {
    monitoring = lib.flatten [
      (mkHomepageService {
        name = "Grafana";
        icon = serviceIcons.Grafana;
        description = "monitoring dashboard";
        enable = serviceEnabled [
          "services"
          "grafana"
          "enable"
        ];
        href = publicUrl "grafana";
        widget = {
          type = "grafana";
          url = internalUrl "grafana";
          username = "{{HOMEPAGE_VAR_GRAFANA_USERNAME}}";
          password = "{{HOMEPAGE_VAR_GRAFANA_PASSWORD}}";
        };
      })

      (mkHomepageService {
        name = "Prometheus";
        icon = serviceIcons.Prometheus;
        description = "metrics scraper";
        enable = serviceEnabled [
          "services"
          "prometheus"
          "enable"
        ];
        href = hrefOr "prometheus" "http://127.0.0.1:${toString config.services.prometheus.port}";
        widget = {
          type = "prometheus";
          url = hrefOr "prometheus" "http://127.0.0.1:${toString config.services.prometheus.port}";
        };
      })
    ];
  }

  {
    network = lib.flatten [ ];
  }
]
