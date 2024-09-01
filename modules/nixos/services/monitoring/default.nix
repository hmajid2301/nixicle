{
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
    sops.secrets.home_assistant_token = {
      sopsFile = ../secrets.yaml;
    };

    sops.secrets.grafana_oauth2_client_id = {
      sopsFile = ../secrets.yaml;
      owner = "grafana";
    };

    sops.secrets.grafana_oauth2_client_secret = {
      sopsFile = ../secrets.yaml;
      owner = "grafana";
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
            };

            routers = {
              prometheus = {
                entryPoints = ["websecure"];
                rule = "Host(`prometheus.bare.homelab.haseebmajid.dev`)";
                service = "prometheus";
                tls.certResolver = "letsencrypt";
              };
              grafana = {
                entryPoints = ["websecure"];
                rule = "Host(`grafana.bare.homelab.haseebmajid.dev`)";
                service = "grafana";
                tls.certResolver = "letsencrypt";
              };
              promtail = {
                entryPoints = ["websecure"];
                rule = "Host(`promtail.bare.homelab.haseebmajid.dev`)";
                service = "promtail";
                tls.certResolver = "letsencrypt";
              };
              alertmanager = {
                entryPoints = ["websecure"];
                rule = "Host(`alertmanager.bare.homelab.haseebmajid.dev`)";
                service = "alertmanager";
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
                  {url = with config.services.gotify; "http://localhost:${environment.GOTIFY_SERVER_PORT}";} # alertmanger-ntfy
                ];
              }
            ];
          };
        };

        exporters = {
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

      loki = {
        enable = true;
        configuration = {
          server.http_listen_port = 3030;
          auth_enabled = false;
          ingester = {
            lifecycler = {
              ring = {
                kvstore = {
                  store = "inmemory";
                };
                replication_factor = 1;
              };
            };
            chunk_idle_period = "5m";
            chunk_retain_period = "30s";
          };
          schema_config = {
            configs = [
              {
                from = "2020-10-24";
                store = "boltdb-shipper";
                object_store = "filesystem";
                schema = "v13";
                index = {
                  prefix = "index_";
                  period = "24h";
                };
              }
            ];
          };
          storage_config = {
            boltdb_shipper = {
              active_index_directory = "/var/lib/loki/index";
              cache_location = "/var/lib/loki/cache";
            };
            filesystem = {
              directory = "/var/lib/loki/chunks";
            };
          };
          limits_config = {
            reject_old_samples = true;
            reject_old_samples_max_age = "168h";
            allow_structured_metadata = false;
          };
          compactor = {
            working_directory = "/var/lib/loki/compactor";
          };
        };
      };

      promtail = {
        enable = true;
        configuration = {
          server = {
            http_listen_port = 3031;
            grpc_listen_port = 0;
          };
          positions = {
            filename = "/tmp/positions.yaml";
          };
          clients = [
            {
              url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
            }
          ];
          scrape_configs = [
            {
              job_name = "journal";
              journal = {
                max_age = "12h";
                labels = {
                  job = "systemd-journal";
                  # TODO: do not hardcode
                  host = "ms01";
                };
              };
              relabel_configs = [
                {
                  source_labels = ["__journal__systemd_unit"];
                  target_label = "unit";
                }
              ];
            }
          ];
        };
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
            port = 3010;
            protocol = "http";
            addr = "127.0.0.1";
          };

          # "auth" = {
          #   signout_redirect_url = "https://authentik.haseebmajid.dev/application/o/grafana/end-session/";
          #   oauth_auto_login = true;
          # };
          #
          # "auth.generic_oauth" = {
          #   enabled = true;
          #   client_id = "$__file{${config.sops.secrets.grafana_oauth2_client_id.path}}";
          #   client_secret = "$__file{${config.sops.secrets.grafana_oauth2_client_secret.path}}";
          #   scopes = "openid profile email";
          #   auth_url = "https://authentik.haseebmajid.dev/application/o/authorize/";
          #   token_url = "https://authentik.haseebmajid.dev/application/o/token/";
          #   api_url = "https://authentik.haseebmajid.dev/application/o/userinfo/";
          #   role_attribute_path = "contains(groups, 'Grafana Admins') && 'Admin' || contains(groups, 'Grafana Editors') && 'Editor' || 'Viewer'";
          # };
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
                  url = "http://127.0.0.1:${toString config.services.prometheus.port}";
                }
                {
                  name = "Loki";
                  type = "loki";
                  access = "proxy";
                  url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
                }
              ];
            };
          };
        };
      };
    };
  };
}
