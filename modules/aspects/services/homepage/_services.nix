# Homepage service definitions
# Trimmed to only apps currently running on the VPS.
[
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
        Papra = {
          icon = "papra.png";
          href = "{{HOMEPAGE_VAR_PAPRA_URL}}";
          description = "read-it-later";
          widget = {
            type = "karakeep";
            url = "{{HOMEPAGE_VAR_PAPRA_INTERNAL_URL}}";
            key = "{{HOMEPAGE_VAR_PAPRA_API_KEY}}";
          };
        };
      }
      {
        Karakeep = {
          icon = "karakeep.png";
          href = "{{HOMEPAGE_VAR_KARAKEEP_URL}}";
          description = "read-it-later";
          widget = {
            type = "karakeep";
            url = "{{HOMEPAGE_VAR_KARAKEEP_INTERNAL_URL}}";
            key = "{{HOMEPAGE_VAR_KARAKEEP_API_KEY}}";
          };
        };
      }
    ];
  }
  {
    internal = [
      {
        Atuin = {
          icon = "atuin.png";
          href = "{{HOMEPAGE_VAR_ATUIN_URL}}";
          description = "shell history sync";
        };
      }
      {
        BanterBus = {
          icon = "banterbus.png";
          href = "{{HOMEPAGE_VAR_BANTERBUS_URL}}";
          description = "quiz server";
        };
      }
      {
        Goroutinely = {
          icon = "goroutinely.png";
          href = "{{HOMEPAGE_VAR_GOROUTINELY_URL}}";
          description = "background jobs";
        };
      }
      {
        LettuceGo = {
          icon = "lettucego.png";
          href = "{{HOMEPAGE_VAR_LETTUCEGO_URL}}";
          description = "group decisions";
        };
      }
      {
        TinyAuth = {
          icon = "tinyauth.png";
          href = "{{HOMEPAGE_VAR_TINYAUTH_URL}}";
          description = "auth proxy";
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
            username = "{{HOMEPAGE_VAR_GRAFANA_USERNAME}}";
            password = "{{HOMEPAGE_VAR_GRAFANA_PASSWORD}}";
          };
        };
      }
      {
        Prometheus = {
          icon = "prometheus.png";
          href = "{{HOMEPAGE_VAR_PROMETHEUS_URL}}";
          description = "metrics scraper";
          widget = {
            type = "prometheus";
            url = "{{HOMEPAGE_VAR_PROMETHEUS_INTERNAL_URL}}";
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
    ];
  }
  {
    network = [
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
      {
        Garage = {
          icon = "garage.png";
          href = "{{HOMEPAGE_VAR_GARAGE_URL}}";
          description = "s3-compatible store";
        };
      }
      {
        Tangled = {
          icon = "tangled.png";
          href = "{{HOMEPAGE_VAR_TANGLED_URL}}";
          description = "activitypub";
        };
      }
    ];
  }
]
