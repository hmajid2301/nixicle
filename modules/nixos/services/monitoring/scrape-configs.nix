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
    services.prometheus.scrapeConfigs = [
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
        job_name = "otel-collector";
        static_configs = [
          {
            targets = [
              "127.0.0.1:8889"
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
}
