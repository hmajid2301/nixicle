{ ... }:
{
  den.aspects.otel-collector = {
    includes = [ ];
    persist.directories = [
      {
        directory = "/var/lib/private/opentelemetry-collector";
        mode = "0755";
      }
    ];
    nixos =
      {
        pkgs,
        ...
      }:
      {
        services.opentelemetry-collector = {
          enable = true;
          package = pkgs.opentelemetry-collector-contrib;
          settings = {
            receivers = {
              otlp.protocols.http.endpoint = "127.0.0.1:3333";
              journald = {
                directory = "/var/log/journal";
                files = [ "/var/log/journal/*/*" ];
                start_at = "end";
                retry_on_failure = {
                  enabled = true;
                  initial_interval = "1s";
                  max_interval = "30s";
                };
              };
            };
            processors = {
              batch = { };
              transform = { };
            };
            exporters = {
              "prometheus".endpoint = "0.0.0.0:8889";
              "otlphttp/loki".endpoint = "http://127.0.0.1:3030/otlp/v1/logs";
              "otlphttp/tempo".endpoint = "http://127.0.0.1:4318";
            };
            service = {
              telemetry = { };
              pipelines = {
                "metrics/prometheus" = {
                  receivers = [ "otlp" ];
                  processors = [
                    "batch"
                    "transform"
                  ];
                  exporters = [ "prometheus" ];
                };
                "logs/loki" = {
                  receivers = [
                    "otlp"
                    "journald"
                  ];
                  processors = [ "batch" ];
                  exporters = [ "otlphttp/loki" ];
                };
                "traces/tempo" = {
                  receivers = [ "otlp" ];
                  processors = [ "batch" ];
                  exporters = [ "otlphttp/tempo" ];
                };
              };
            };
          };
        };

      };
  };
}
