{ ... }:
{
  den.aspects.monitoring = {
    includes = [ ];
    persist.directories = [
      {
        directory = "/var/lib/prometheus2";
        mode = "0755";
      }
      {
        directory = "/var/lib/grafana";
        mode = "0755";
      }
      {
        directory = "/var/lib/private/alertmanager";
        mode = "0750";
      }
      {
        directory = "/var/lib/loki";
        mode = "0755";
      }
      {
        directory = "/var/lib/private/tempo";
        mode = "0750";
      }
    ];
    nixos =
      { config, lib, ... }:
      {
        services = {
          prometheus = {
            port = 3020;
            enable = true;
            checkConfig = "syntax-only";
            extraFlags = [
              "--web.enable-admin-api"
              "--storage.tsdb.retention.time=30d"
            ];

            exporters = {
              redis.enable = true;
              postgres.enable = true;
              node = {
                port = 3021;
                enabledCollectors = [ "systemd" ];
                enable = true;
              };
            };

            scrapeConfigs = [
              {
                job_name = "redis";
                metrics_path = "/metrics";
                static_configs = [
                  { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.redis.port}" ]; }
                ];
              }
              {
                job_name = "postgres";
                static_configs = [
                  { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.postgres.port}" ]; }
                ];
              }
              {
                job_name = "otel-collector";
                static_configs = [ { targets = [ "127.0.0.1:8889" ]; } ];
              }
              {
                job_name = "nodes";
                static_configs = [
                  { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ]; }
                ];
              }
            ];

            alertmanager = {
              enable = true;
              configuration = {
                route = {
                  receiver = "all";
                  group_by = [ "instance" ];
                  group_wait = "30s";
                  group_interval = "2m";
                  repeat_interval = "24h";
                };
                receivers = [
                  {
                    name = "all";
                    webhook_configs = [ { url = "http://127.0.0.1:11000/alert"; } ];
                  }
                ];
              };
            };
          };

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
                auth_url = "https://authentik.haseebmajid.dev/application/o/authorize/";
                token_url = "https://authentik.haseebmajid.dev/application/o/token/";
                api_url = "https://authentik.haseebmajid.dev/application/o/userinfo/";
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

          loki = {
            enable = true;
            configuration = {
              server = {
                http_listen_port = 3030;
                grpc_listen_port = 3031;
              };
              auth_enabled = false;
              ingester = {
                lifecycler = {
                  address = "127.0.0.1";
                  ring = {
                    kvstore.store = "inmemory";
                    replication_factor = 1;
                  };
                };
                chunk_idle_period = "1h";
                max_chunk_age = "1h";
                chunk_target_size = 999999;
                chunk_retain_period = "30s";
              };
              schema_config.configs = [
                {
                  from = "2024-04-01";
                  store = "tsdb";
                  object_store = "filesystem";
                  schema = "v13";
                  index = {
                    prefix = "index_";
                    period = "24h";
                  };
                }
              ];
              storage_config = {
                tsdb_shipper = {
                  active_index_directory = "/var/lib/loki/tsdb-index";
                  cache_location = "/var/lib/loki/tsdb-cache";
                };
                filesystem.directory = "/var/lib/loki/chunks";
              };
              limits_config = {
                reject_old_samples = true;
                reject_old_samples_max_age = "168h";
              };
              table_manager = {
                retention_deletes_enabled = false;
                retention_period = "0s";
              };
              compactor = {
                working_directory = "/var/lib/loki";
                compactor_ring.kvstore.store = "inmemory";
              };
            };
          };

          tempo = {
            enable = true;
            settings = {
              server = {
                http_listen_port = 4400;
                grpc_listen_port = 4401;
              };
              memberlist.bind_port = 7947;
              distributor.receivers.otlp.protocols = {
                http.endpoint = "0.0.0.0:4318";
                grpc.endpoint = "0.0.0.0:4317";
              };
              storage.trace = {
                backend = "local";
                local.path = "/var/lib/tempo";
                wal.path = "/var/lib/tempo/wal";
              };
            };
          };

          traefik.dynamicConfigOptions.http = lib.mkMerge [
            (lib.nixicle.mkTraefikService {
              name = "prometheus";
              port = 3020;
            })
            (lib.nixicle.mkTraefikService {
              name = "grafana";
              port = 3010;
            })
            (lib.nixicle.mkTraefikService {
              name = "alertmanager";
              port = 9093;
            })
            (lib.nixicle.mkTraefikService {
              name = "tempo";
              port = 4400;
            })
          ];
        };

        sops.secrets = {
          grafana_oauth2_client_id = {
                        owner = "grafana";
          };
          grafana_oauth2_client_secret = {
                        owner = "grafana";
          };
          grafana_secret_key = {
                        owner = "grafana";
          };
        };

        systemd = {
          services = {
            loki.serviceConfig = {
              StateDirectory = "loki";
              StateDirectoryMode = "0755";
            };
            tempo.serviceConfig = {
              StateDirectory = "tempo";
              StateDirectoryMode = "0755";
            };
          };
        };
      };
  };
}
