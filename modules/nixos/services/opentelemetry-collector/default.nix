{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.otel-collector;
in
{
  options.services.nixicle.otel-collector = {
    enable = mkEnableOption "Enable the otel collector service";
  };

  config = mkIf cfg.enable {
    services = {
      opentelemetry-collector = {
        enable = true;
        package = pkgs.opentelemetry-collector-contrib;
        settings = {
          receivers = {
            otlp.protocols.http = {
              endpoint = "0.0.0.0:3333";
            };
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
            "prometheus" = {
              endpoint = "0.0.0.0:8889";
            };
            "loki" = {
              endpoint = "http://127.0.0.1:3030/loki/api/v1/push";
            };
            "otlphttp/tempo" = {
              endpoint = "http://127.0.0.1:4318";
            };
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
                exporters = [ "loki" ];
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

      traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "otel-collector";
        port = 3333;
      };
    };

    systemd.services.opentelemetry-collector = {
      serviceConfig = {
        StateDirectory = "otelcol";
        StateDirectoryMode = "0755";
      };
    };

    environment.persistence = mkIf config.system.impermanence.enable {
      "/persist" = {
        directories = [
          { directory = "/var/lib/otelcol"; user = "otelcol-contrib"; group = "otelcol-contrib"; mode = "0755"; }
        ];
      };
    };
  };
}
