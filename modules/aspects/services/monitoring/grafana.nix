_: {
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
                http_addr = "127.0.0.1";
                root_url = "https://grafana.${config.nixicle.domains.homelab}";
              };
              "auth.generic_oauth" = {
                enabled = true;
                client_id = "$__file{${config.sops.secrets.grafana_oauth2_client_id.path}}";
                client_secret = "$__file{${config.sops.secrets.grafana_oauth2_client_secret.path}}";
                scopes = "openid profile email groups";
                auth_url = "https://${config.nixicle.domains.sso}/authorize";
                token_url = "https://${config.nixicle.domains.sso}/api/oidc/token";
                api_url = "https://${config.nixicle.domains.sso}/api/oidc/userinfo";
                role_attribute_path = "contains(groups, 'Grafana Admins') && 'Admin' || contains(groups, 'Grafana Editors') && 'Editor' || 'Viewer'";
              };
              auth.oauth_allow_insecure_email_lookup = true;
              auth.disable_login_form = true;
              # Homepage widget hits /api/admin/stats, which needs server-admin
              # basic auth (service accounts can't hold the Grafana Admin role).
              # The widget reaches this over localhost; humans sign in with SSO.
              "auth.basic".enabled = true;
              security.admin_password = "$__file{${config.sops.secrets.grafana_admin_password.path}}";
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
                  uid = "prometheus";
                  access = "proxy";
                  editable = true;
                  url = "http://127.0.0.1:${toString config.services.prometheus.port}";
                }
                {
                  name = "Loki";
                  type = "loki";
                  uid = "loki";
                  access = "proxy";
                  editable = true;
                  url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
                }
                {
                  name = "Tempo";
                  type = "tempo";
                  uid = "tempo";
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
          grafana_admin_password.owner = "grafana";
          grafana_oauth2_client_id.owner = "grafana";
          grafana_oauth2_client_secret.owner = "grafana";
          grafana_secret_key.owner = "grafana";
        };
      };
  };
}
