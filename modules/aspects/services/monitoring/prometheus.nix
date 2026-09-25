_: {
  den.aspects.monitoringPrometheus = {
    persist.directories = [
      {
        directory = "/var/lib/prometheus2";
        mode = "0755";
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
            postgres = {
              enable = true;
              runAsLocalSuperUser = true;
            };
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
            {
              job_name = "crowdsec";
              static_configs = [ { targets = [ "127.0.0.1:6060" ]; } ];
            }
            {
              job_name = "traefik";
              static_configs = [ { targets = [ "127.0.0.1:8080" ]; } ];
            }
            {
              job_name = "loki";
              static_configs = [ { targets = [ "127.0.0.1:3030" ]; } ];
            }
            {
              job_name = "tempo";
              static_configs = [ { targets = [ "127.0.0.1:4400" ]; } ];
            }
            {
              job_name = "garage";
              static_configs = [ { targets = [ "127.0.0.1:3903" ]; } ];
            }
            {
              job_name = "prometheus";
              static_configs = [ { targets = [ "127.0.0.1:${toString config.services.prometheus.port}" ]; } ];
            }
          ];
        };
      };
  };
}
