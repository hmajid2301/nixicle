{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.homepage;
in {
  options.services.nixicle.homepage = {
    enable = mkEnableOption "Enable homepage for homelab services";
  };

  config = mkIf cfg.enable {
    sops.secrets.homepage_env = {
      sopsFile = ../secrets.yaml;
    };

    services = {
      homepage-dashboard = {
        enable = true;
        environmentFile = config.sops.secrets.homepage_env.path;
        listenPort = 8173;
        bookmarks = [];
        services = [
          {
            external = [
              {
                Tandoor = {
                  icon = "tandoor.png";
                  href = "{{HOMEPAGE_VAR_TANDOOR_URL}}";
                  description = "recipe management";
                  widget = {
                    type = "tandoor";
                    url = "{{HOMEPAGE_VAR_TANDOOR_INTERNAL_URL}}";
                    key = "{{HOMEPAGE_VAR_TANDOOR_API_KEY}}";
                  };
                };
              }
              {
                Audiobookshelf = {
                  icon = "audiobookshelf.png";
                  href = "{{HOMEPAGE_VAR_AUDIOBOOKSHELF_URL}}";
                  description = "audio books management";
                  widget = {
                    type = "audiobookshelf";
                    url = "{{HOMEPAGE_VAR_AUDIOBOOKSHELF_INTERNAL_URL}}";
                    key = "{{HOMEPAGE_VAR_AUDIOBOOKSHELF_API_KEY}}";
                  };
                };
              }
              {
                Paperless = {
                  icon = "paperless.png";
                  href = "{{HOMEPAGE_VAR_PAPERLESS_URL}}";
                  description = "document management";
                  widget = {
                    type = "paperlessngx";
                    url = "{{HOMEPAGE_VAR_PAPERLESS_INTERNAL_URL}}";
                    key = "{{HOMEPAGE_VAR_PAPERLESS_API_KEY}}";
                  };
                };
              }
              {
                Jellyseerr = {
                  icon = "jellyseerr.png";
                  href = "{{HOMEPAGE_VAR_JELLYSEERR_URL}}";
                  description = "request management";
                  widget = {
                    type = "jellyseerr";
                    url = "{{HOMEPAGE_VAR_JELLYSEERR_INTERNAL_URL}}";
                    key = "{{HOMEPAGE_VAR_JELLYSEERR_API_KEY}}";
                  };
                };
              }
              {
                Syncthing = {
                  icon = "syncthing.png";
                  href = "{{HOMEPAGE_VAR_HOME_SYNCTHING_URL}}";
                  description = "file syncing";
                  widget = {
                    type = "strelaysrv";
                    url = "{{HOMEPAGE_VAR_SYNCTHING_INTERNAL_URL}}";
                  };
                };
              }
              {
                Gitea = {
                  icon = "gitea.png";
                  href = "{{HOMEPAGE_VAR_GITEA_URL}}";
                  description = "git server";
                  widget = {
                    type = "gitea";
                    url = "{{HOMEPAGE_VAR_GITEA_INTERNAL_URL}}";
                    key = "{{HOMEPAGE_VAR_GITEA_API_KEY}}";
                  };
                };
              }
              {
                HomeAssistant = {
                  icon = "home-assistant.png";
                  href = "{{HOMEPAGE_VAR_HOME_ASSISTANT_URL}}";
                  description = "home automation";
                  widget = {
                    type = "homeassistant";
                    url = "{{HOMEPAGE_VAR_HOME_ASSISTANT_INTERNAL_URL}}";
                    key = "{{HOMEPAGE_VAR_HOME_ASSISTANT_API_KEY}}";
                  };
                };
              }
              {
                Authentik = {
                  icon = "authentik.png";
                  href = "{{HOMEPAGE_VAR_AUTHENTIK_URL}}";
                  description = "auth management";
                  widget = {
                    type = "authentik";
                    url = "{{HOMEPAGE_VAR_AUTHENTIK_INTERNAL_URL}}";
                    key = "{{HOMEPAGE_VAR_AUTHENTIK_API_KEY}}";
                  };
                };
              }
            ];
          }
          {
            monitoring = [
              {
                Grafana = {
                  icon = "grafana.png";
                  href = "{{HOMEPAGE_VAR_GRAFANA_URL}}";
                  description = "monitoring dashboard";
                  widget = {
                    type = "grafana";
                    url = "{{HOMEPAGE_VAR_GRAFANA_INTERNAL_URL}}";
                    key = "{{HOMEPAGE_VAR_GRAFANA_API_KEY}}";
                  };
                };
              }
              {
                Prometheus = {
                  icon = "prometheus.png";
                  href = "{{HOMEPAGE_VAR_PROMETHEUS_URL}}";
                  description = "metrics scrapper";
                  widget = {
                    type = "prometheus";
                    url = "{{HOMEPAGE_VAR_PROMETHEUS_INTERNAL_URL}}";
                  };
                };
              }
              {
                Netdata = {
                  icon = "netdata.png";
                  href = "{{HOMEPAGE_VAR_NETDATA_URL}}";
                  description = "pc monitoring";
                  widget = {
                    type = "netdata";
                    url = "{{HOMEPAGE_VAR_NETDATA_INTERNAL_URL}}";
                  };
                };
              }
              {
                Traefik = {
                  icon = "traefik.png";
                  href = "{{HOMEPAGE_VAR_TRAEFIK_URL}}";
                  description = "reverse proxy";
                  widget = {
                    type = "traefik";
                    url = "{{HOMEPAGE_VAR_TRAEFIK_INTERNAL_URL}}";
                  };
                };
              }
              {
                Gotify = {
                  icon = "gotify.png";
                  href = "{{HOMEPAGE_VAR_GOTIFY_URL}}";
                  description = "notification service";
                  widget = {
                    type = "gotify";
                    url = "{{HOMEPAGE_VAR_GOTIFY_INTERNAL_URL}}";
                    key = "{{HOMEPAGE_VAR_GOTIFY_API_KEY}}";
                  };
                };
              }
            ];
          }
          {
            media = [
              {
                Jellyfin = {
                  icon = "jellyfin.png";
                  href = "{{HOMEPAGE_VAR_JELLYFIN_URL}}";
                  description = "media management";
                  widget = {
                    type = "jellyfin";
                    url = "{{HOMEPAGE_VAR_JELLYFIN_INTERNAL_URL}}";
                    key = "{{HOMEPAGE_VAR_JELLYFIN_API_KEY}}";
                  };
                };
              }

              {
                Radarr = {
                  icon = "radarr.png";
                  href = "{{HOMEPAGE_VAR_RADARR_URL}}";
                  description = "film management";
                  widget = {
                    type = "radarr";
                    url = "{{HOMEPAGE_VAR_RADARR_INTERNAL_URL}}";
                    key = "{{HOMEPAGE_VAR_RADARR_API_KEY}}";
                  };
                };
              }
              {
                Sonarr = {
                  icon = "sonarr.png";
                  href = "{{HOMEPAGE_VAR_SONARR_URL}}";
                  description = "tv management";
                  widget = {
                    type = "sonarr";
                    url = "{{HOMEPAGE_VAR_SONARR_INTERNAL_URL}}";
                    key = "{{HOMEPAGE_VAR_SONARR_API_KEY}}";
                  };
                };
              }
              {
                Lidarr = {
                  icon = "lidarr.png";
                  href = "{{HOMEPAGE_VAR_LIDARR_URL}}";
                  description = "music management";
                  widget = {
                    type = "lidarr";
                    url = "{{HOMEPAGE_VAR_LIDARR_INTERNAL_URL}}";
                    key = "{{HOMEPAGE_VAR_LIDARR_API_KEY}}";
                  };
                };
              }
              {
                Readarr = {
                  icon = "readarr.png";
                  href = "{{HOMEPAGE_VAR_READARR_URL}}";
                  description = "book management";
                  widget = {
                    type = "readarr";
                    url = "{{HOMEPAGE_VAR_READARR_INTERNAL_URL}}";
                    key = "{{HOMEPAGE_VAR_READARR_API_KEY}}";
                  };
                };
              }
              {
                Prowlarr = {
                  icon = "prowlarr.png";
                  href = "{{HOMEPAGE_VAR_PROWLARR_URL}}";
                  description = "index management";
                  widget = {
                    type = "prowlarr";
                    url = "{{HOMEPAGE_VAR_PROWLARR_INTERNAL_URL}}";
                    key = "{{HOMEPAGE_VAR_PROWLARR_API_KEY}}";
                  };
                };
              }
              {
                Bazarr = {
                  icon = "bazarr.png";
                  href = "{{HOMEPAGE_VAR_BAZARR_URL}}";
                  description = "subtitles management";
                  widget = {
                    type = "bazarr";
                    url = "{{HOMEPAGE_VAR_BAZARR_INTERNAL_URL}}";
                    key = "{{HOMEPAGE_VAR_BAZARR_API_KEY}}";
                  };
                };
              }
              {
                Deluge = {
                  icon = "deluge.png";
                  href = "{{HOMEPAGE_VAR_DELUGE_URL}}";
                  description = "torrent client";
                  widget = {
                    type = "deluge";
                    url = "{{HOMEPAGE_VAR_DELUGE_INTERNAL_URL}}";
                    key = "{{HOMEPAGE_VAR_DELUGE_PASSWORD}}";
                  };
                };
              }
            ];
          }
          {
            disk = [
              {
                Synology = {
                  icon = "synology.png";
                  href = "{{HOMEPAGE_VAR_SYNOLOGY_URL}}";
                  description = "NAS";
                  widget = {
                    type = "diskstation";
                    url = "{{HOMEPAGE_VAR_SYNOLOGY_INTERNAL_URL}}";
                    username = "{{HOMEPAGE_VAR_SYNOLOGY_USERNAME}}";
                    password = "{{HOMEPAGE_VAR_SYNOLOGY_PASSWORD}}";
                  };
                };
              }
            ];
          }
          {
            network = [
              {
                Adguard = {
                  icon = "adguard-home.png";
                  href = "{{HOMEPAGE_VAR_ADGUARD_URL}}";
                  description = "dns block";
                  widget = {
                    type = "adguard";
                    url = "{{HOMEPAGE_VAR_ADGUARD_INTERNAL_URL}}";
                    username = "{{HOMEPAGE_VAR_ADGUARD_USERNAME}}";
                    password = "{{HOMEPAGE_VAR_ADGUARD_PASSWORD}}";
                  };
                };
              }
              {
                Cloudflare = {
                  icon = "cloudflare.png";
                  href = "{{HOMEPAGE_VAR_CLOUDFLARE_URL}}";
                  description = "cloudflare tunnel";
                  widget = {
                    type = "cloudflared";
                    accountid = "{{HOMEPAGE_VAR_CLOUDFLARE_ACCOUNT_ID}}";
                    tunnelid = "ec0b6af0-a823-4616-a08b-b871fd2c7f58";
                    key = "{{HOMEPAGE_VAR_CLOUDFLARE_KEY}}";
                  };
                };
              }
              {
                Tailscale = {
                  icon = "tailscale.png";
                  href = "{{HOMEPAGE_VAR_TAILSCALE_URL}}";
                  description = "vpn connected devices";
                  widget = {
                    type = "tailscale";
                    deviceid = "{{HOMEPAGE_VAR_TAILSCALE_DEVICE_ID}}";
                    key = "{{HOMEPAGE_VAR_TAILSCALE_KEY}}";
                  };
                };
              }
            ];
          }
        ];
        settings = {
          title = "Homelab Dashboard";
          favicon = "https://haseebmajid.dev/favicon.ico";
          headerStyle = "clean";
          layout = {
            external = {
              style = "row";
              columns = 3;
            };
            media = {
              style = "row";
              columns = 3;
            };
            network = {
              style = "row";
              columns = 2;
            };
            monitoring = {
              style = "row";
              columns = 2;
            };
            disk = {
              style = "row";
              columns = 2;
            };
          };
        };
        widgets = [
          {
            search = {
              provider = "custom";
              url = "https://kagi.com/search?q=";
              target = "_blank";
              suggestionUrl = "https://kagi.com/autocomplete?type=list&q="; # Optional
              showSearchSuggestions = true; # Optional
            };
          }
          {
            resources = {
              label = "system";
              cpu = true;
              memory = true;
            };
          }
          {
            resources = {
              label = "storage";
              disk = ["/mnt/share/"];
            };
          }
          {
            openmeteo = {
              label = "London";
              timezone = "Europe/London";
              latitude = "{{HOMEPAGE_VAR_LATITUDE}}";
              longitude = "{{HOMEPAGE_VAR_LONGITUDE}}";
              units = "metric";
            };
          }
        ];
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services.homepage.loadBalancer.servers = [
              {
                url = "http://localhost:8173";
              }
            ];

            routers = {
              homepage = {
                entryPoints = ["websecure"];
                rule = "Host(`homepage.bare.homelab.haseebmajid.dev`)";
                service = "homepage";
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
