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
            media = [
              {
                Jellyfin = {
                  icon = "jellyfin.png";
                  href = "{{HOMEPAGE_VAR_JELLYFIN_URL}}";
                  description = "media management";
                  widget = {
                    type = "jellyfin";
                    url = "{{HOMEPAGE_VAR_JELLYFIN_URL}}";
                    key = "{{HOMEPAGE_VAR_JELLYFIN_API_KEY}}";
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
                    url = "{{HOMEPAGE_VAR_JELLYSEERR_URL}}";
                    key = "{{HOMEPAGE_VAR_JELLYSEERR_API_KEY}}";
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
                    url = "{{HOMEPAGE_VAR_RADARR_URL}}";
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
                    url = "{{HOMEPAGE_VAR_SONARR_URL}}";
                    key = "{{HOMEPAGE_VAR_SONARR_API_KEY}}";
                  };
                };
              }
              {
                Lidarr = {
                  icon = "Lidarr.png";
                  href = "{{HOMEPAGE_VAR_LIDARR_URL}}";
                  description = "";
                  widget = {
                    type = "music management";
                    url = "{{HOMEPAGE_VAR_LIDARR_URL}}";
                    key = "{{HOMEPAGE_VAR_LIDARR_API_KEY}}";
                  };
                };
              }
              {
                Readarr = {
                  icon = "Readarr.png";
                  href = "{{HOMEPAGE_VAR_READARR_URL}}";
                  description = "book management";
                  widget = {
                    type = "readarr";
                    url = "{{HOMEPAGE_VAR_READARR}}";
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
                    url = "{{HOMEPAGE_VAR_PROWLARR_URL}}";
                    key = "{{HOMEPAGE_VAR_PROWLARR_API_KEY}}";
                  };
                };
              }
            ];
          }
          {
            network = [
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
            media = {
              style = "row";
              columns = 3;
            };
            network = {
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
              disk = ["/mnt/share/haseeb/homelab"];
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
