{ ... }:
{
  den.aspects.monitoringLoki = {
    persist.directories = [
      {
        directory = "/var/lib/loki";
        mode = "0755";
      }
    ];

    nixos = {
      services.loki = {
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
            allow_structured_metadata = true;
            retention_period = "4320h";
          };
          compactor = {
            working_directory = "/var/lib/loki";
            compactor_ring.kvstore.store = "inmemory";
            retention_enabled = true;
            delete_request_store = "filesystem";
          };
        };
      };

      systemd.services.loki.serviceConfig = {
        StateDirectory = "loki";
        StateDirectoryMode = "0755";
      };
    };
  };
}
