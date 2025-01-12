{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.logging;
in {
  options.services.nixicle.logging = {
    enable = mkEnableOption "Enable The log collection";
  };

  config = mkIf cfg.enable {
    services = {
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
              url = "http://127.0.0.1:3030/loki/api/v1/push";
            }
          ];
          scrape_configs = [
            {
              job_name = "journal";
              journal = {
                max_age = "12h";
                labels = {
                  job = "systemd-journal";
                  host = config.networking.hostName;
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
    };
  };
}
