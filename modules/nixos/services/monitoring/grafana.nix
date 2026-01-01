{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.monitoring;
in
{
  config = mkIf cfg.enable {
    sops.secrets = {
      grafana_oauth2_client_id = {
        sopsFile = ../secrets.yaml;
        owner = "grafana";
      };

      grafana_oauth2_client_secret = {
        sopsFile = ../secrets.yaml;
        owner = "grafana";
      };
    };

    services.postgresql = {
      ensureDatabases = [ "grafana" ];
      ensureUsers = [
        {
          name = "grafana";
          ensureDBOwnership = true;
        }
      ];
    };

    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_port = 3010;
          http_addr = "0.0.0.0";
          root_url = "https://grafana.homelab.haseebmajid.dev";
        };

        # "auth" = {
        #   signout_redirect_url = "https://authentik.haseebmajid.dev/application/o/grafana/end-session/";
        #   oauth_auto_login = true;
        # };

        "auth.generic_oauth" = {
          enabled = true;
          client_id = "$__file{${config.sops.secrets.grafana_oauth2_client_id.path}}";
          client_secret = "$__file{${config.sops.secrets.grafana_oauth2_client_secret.path}}";
          scopes = "openid profile email";
          auth_url = "https://authentik.haseebmajid.dev/application/o/authorize/";
          token_url = "https://authentik.haseebmajid.dev/application/o/token/";
          api_url = "https://authentik.haseebmajid.dev/application/o/userinfo/";
          role_attribute_path = "contains(groups, 'Grafana Admins') && 'Admin' || contains(groups, 'Grafana Editors') && 'Editor' || 'Viewer'";
        };
        database = {
          host = "/run/postgresql";
          user = "grafana";
          name = "grafana";
          type = "postgres";
        };
      };

      provision = {
        enable = true;
        datasources = {
          settings = {
            datasources = [
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
      };
    };

    environment.persistence = mkIf config.system.impermanence.enable {
      "/persist" = {
        directories = [
          { directory = "/var/lib/grafana"; user = "grafana"; group = "grafana"; mode = "0755"; }
        ];
      };
    };
  };
}
