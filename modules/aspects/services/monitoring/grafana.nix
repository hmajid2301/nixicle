{ ... }:
{
  den.aspects.monitoringGrafana = {
    persist.directories = [
      {
        directory = "/var/lib/grafana";
        mode = "0755";
      }
    ];

    nixos =
      { config, lib, ... }:
      {
        services = {
          grafana = {
            enable = true;
            settings = {
              server = {
                http_port = 3010;
                http_addr = "0.0.0.0";
                root_url = "https://grafana.homelab.haseebmajid.dev";
              };
              "auth.generic_oauth" = {
                enabled = true;
                client_id = "$__file{${config.sops.secrets.grafana_oauth2_client_id.path}}";
                client_secret = "$__file{${config.sops.secrets.grafana_oauth2_client_secret.path}}";
                scopes = "openid profile email";
                auth_url = "https://id.haseebmajid.dev/authorize";
                token_url = "https://id.haseebmajid.dev/api/oidc/token";
                api_url = "https://id.haseebmajid.dev/api/oidc/userinfo";
                role_attribute_path = "contains(groups, 'Grafana Admins') && 'Admin' || contains(groups, 'Grafana Editors') && 'Editor' || 'Viewer'";
              };
              security.secret_key = "$__file{${config.sops.secrets.grafana_secret_key.path}}";
              database = {
                host = "/run/postgresql";
                user = "grafana";
                name = "grafana";
                type = "postgres";
              };
            };
            provision = {
              enable = true;
              datasources.settings.datasources = [
                {
                  name = "Prometheus";
                  type = "prometheus";
                  access = "proxy";
                  editable = true;
                  url = "http://127.0.0.1:${toString config.services.prometheus.port}";
                }
                {
                  name = "Loki";
                  type = "loki";
                  access = "proxy";
                  editable = true;
                  url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
                }
                {
                  name = "Tempo";
                  type = "tempo";
                  access = "proxy";
                  editable = true;
                  url = "http://127.0.0.1:${toString config.services.tempo.settings.server.http_listen_port}";
                }
              ];
            };
          };

          postgresql = {
            ensureDatabases = [ "grafana" ];
            ensureUsers = [
              {
                name = "grafana";
                ensureDBOwnership = true;
              }
            ];
          };

          traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
            name = "grafana";
            port = 3010;
          };
        };

        sops.secrets = {
          grafana_oauth2_client_id.owner = "grafana";
          grafana_oauth2_client_secret.owner = "grafana";
          grafana_secret_key.owner = "grafana";
        };
      };
  };
}
