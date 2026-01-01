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
      # {
      #   job_name = "home-assistant";
      #   metrics_path = "/api/prometheus";
      #   bearer_token_file = config.sops.secrets.home_assistant_token.path;
      #   static_configs = [
      #     {
      #       targets = [ "s100:8123" ];
      #     }
      #   ];
      # }

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
