{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.monitoring;
in {
  options.services.nixicle.monitoring = {
    enable = mkEnableOption "Enable The monitoring stack(loki, prometheus, grafana)";
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      home_assistant_token = {
        sopsFile = ../secrets.yaml;
      };

      minio_prometheus_bearer_token = {
        sopsFile = ../secrets.yaml;
      };

      grafana_oauth2_client_id = {
        sopsFile = ../secrets.yaml;
        owner = "grafana";
      };

      grafana_oauth2_client_secret = {
        sopsFile = ../secrets.yaml;
        owner = "grafana";
      };
    };

    services = {
      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              prometheus.loadBalancer.servers = [
                {
                  url = "http://localhost:3020";
                }
              ];
              grafana.loadBalancer.servers = [
                {
                  url = "http://localhost:3010";
                }
              ];
              promtail.loadBalancer.servers = [
                {
                  url = "http://localhost:3031";
                }
              ];
              alertmanager.loadBalancer.servers = [
                {
                  url = "http://localhost:9093";
                }
              ];
              otel-collector.loadBalancer.servers = [
                {
                  url = "http://localhost:4317";
                }
              ];
              tempo.loadBalancer.servers = [
                {
                  url = "http://localhost:4400";
                }
              ];
            };

            routers = {
              prometheus = {
                entryPoints = ["websecure"];
                rule = "Host(`prometheus.homelab.haseebmajid.dev`)";
                service = "prometheus";
                tls.certResolver = "letsencrypt";
              };
              grafana = {
                entryPoints = ["websecure"];
                rule = "Host(`grafana.homelab.haseebmajid.dev`)";
                service = "grafana";
                tls.certResolver = "letsencrypt";
              };
              promtail = {
                entryPoints = ["websecure"];
                rule = "Host(`promtail.homelab.haseebmajid.dev`)";
                service = "promtail";
                tls.certResolver = "letsencrypt";
              };
              alertmanager = {
                entryPoints = ["websecure"];
                rule = "Host(`alertmanager.homelab.haseebmajid.dev`)";
                service = "alertmanager";
                tls.certResolver = "letsencrypt";
              };
              otel-collector = {
                entryPoints = ["websecure"];
                rule = "Host(`otel-collector.homelab.haseebmajid.dev`)";
                service = "otel-collector";
                tls.certResolver = "letsencrypt";
              };
              tempo = {
                entryPoints = ["websecure"];
                rule = "Host(`tempo.homelab.haseebmajid.dev`)";
                service = "tempo";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };

      prometheus = {
        port = 3020;
        enable = true;
        checkConfig = "syntax-only";
        alertmanager = {
          enable = true;
          configuration = {
            # global = {
            # The smarthost and SMTP sender used for mail notifications.
            # smtp_smarthost = "mail.thalheim.io:587";
            # smtp_from = "alertmanager@thalheim.io";
            # smtp_auth_username = "alertmanager@thalheim.io";
            # smtp_auth_password = "$SMTP_PASSWORD";
            # };

            route = {
              receiver = "all";
              group_by = ["instance"];
              group_wait = "30s";
              group_interval = "2m";
              repeat_interval = "24h";
            };

            receivers = [
              {
                name = "all";
                webhook_configs = [
                  {url = "http://127.0.0.1:11000/alert";} # matrix-hook
                  {url = with config.services.gotify; "http://s100:8051";} # alertmanger-ntfy
                ];
              }
            ];
          };
        };

        exporters = {
          redis = {
            enable = true;
          };

          postgres = {
            enable = true;
          };

          node = {
            port = 3021;
            enabledCollectors = ["systemd"];
            enable = true;
          };
        };

        # TODO: work out this is on a different host
        scrapeConfigs = [
          {
            job_name = "home-assistant";
            metrics_path = "/api/prometheus";
            bearer_token_file = config.sops.secrets.home_assistant_token.path;
            static_configs = [
              {
                targets = ["s100:8123"];
              }
            ];
          }

          {
            job_name = "redis";
            metrics_path = "/metrics";
            static_configs = [
              {
                targets = [
                  "127.0.0.1:${toString config.services.prometheus.exporters.redis.port}"
                ];
              }
            ];
          }

          {
            job_name = "postgres";
            static_configs = [
              {
                targets = [
                  "127.0.0.1:${toString config.services.prometheus.exporters.postgres.port}"
                ];
              }
            ];
          }

          {
            job_name = "minio";
            metrics_path = "/minio/metrics/v3";
            bearer_token_file = config.sops.secrets.minio_prometheus_bearer_token.path;
            static_configs = [
              {
                targets = [
                  "127.0.0.1${toString config.services.minio.listenAddress}"
                ];
              }
            ];
          }

          {
            job_name = "nodes";
            static_configs = [
              {
                targets = [
                  "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
                ];
              }
            ];
          }
        ];
      };

      postgresql = {
        ensureDatabases = ["grafana"];
        ensureUsers = [
          {
            name = "grafana";
            ensureDBOwnership = true;
          }
        ];
      };

      grafana = {
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
                  name = "Prometheus (ms01)";
                  type = "prometheus";
                  access = "proxy";
                  editable = true;
                  url = "http://127.0.0.1:${toString config.services.prometheus.port}";
                }
                {
                  name = "Loki (ms01)";
                  type = "loki";
                  access = "proxy";
                  editable = true;
                  url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
                }
                {
                  name = "Loki (s100)";
                  type = "loki";
                  access = "proxy";
                  editable = true;
                  url = "http://s100:3030";
                }
                {
                  name = "Loki (vps)";
                  type = "loki";
                  access = "proxy";
                  editable = true;
                  url = "http://vps:3030";
                }
              ];
            };
          };
        };
      };

      # tempo = {
      #   enable = true;
      #   settings = {
      #     server = {
      #       http_listen_port = 4400;
      #       grpc_listen_port = 4401;
      #     };
      #     # TODO: use s3
      #     storage = {
      #       trace = {
      #         backend = "s3";
      #         s3 = {
      #           bucket = "tempo";
      #           endpoint = "localhost:9095";
      #           tls_insecure_skip_verify = true;
      #           region = "us-east-1";
      #         };
      #       };
      #     };
      #   };
      # };

      # opentelemetry-collector = {
      #   enable = true;
      #   package = pkgs.opentelemetry-collector-contrib;
      #   settings = {
      #     otelcolConfig = {
      #       receivers = {
      #         otlp = {
      #           protocols = {
      #             http = {
      #               endpoint = "localhost:4317";
      #             };
      #           };
      #         };
      #       };
      #
      #       processors = {
      #         batch = {};
      #       };
      #
      #       exporters = {
      #         "otlp" = {
      #           endpoint = "localhost:31100";
      #           tls = {
      #             insecure = true;
      #           };
      #         };
      #         prometheus = {
      #           endpoint = "localhost:3020";
      #         };
      #       };
      #
      #       extensions = {
      #         health_check = {};
      #       };
      #
      #       service = {
      #         extensions = ["health_check"];
      #         pipelines = {
      #           traces = {
      #             receivers = ["otlp"];
      #             processors = ["batch"];
      #             exporters = ["otlp"];
      #           };
      #           metrics = {
      #             receivers = ["otlp"];
      #             processors = ["batch"];
      #             exporters = ["otlp"];
      #           };
      #         };
      #       };
      #     };
      #   };
      # };
    };
  };
}
