{ ... }:
{
  den.aspects.monitoringPrometheus = {
    persist.directories = [
      {
        directory = "/var/lib/prometheus2";
        mode = "0755";
      }
      {
        directory = "/var/lib/private/alertmanager";
        mode = "0750";
      }
    ];

    nixos =
      { config, ... }:
      {
        services.prometheus = {
          port = 3020;
          listenAddress = "127.0.0.1";
          enable = true;
          checkConfig = "syntax-only";
          extraFlags = [
            "--web.enable-admin-api"
            "--storage.tsdb.retention.time=180d"
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
      };
  };
}
