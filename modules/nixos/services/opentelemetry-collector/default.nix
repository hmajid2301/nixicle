{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.otel-collector;
in
{
  options.services.nixicle.otel-collector = {
    enable = mkEnableOption "Enable the otel collector service";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      sops.secrets = {
        otel_betterstack_token = {
          sopsFile = ../secrets.yaml;
        };
      };

      systemd.services.opentelemetry-collector = {
        serviceConfig = {
          EnvironmentFile = [
            config.sops.secrets.otel_betterstack_token.path
          ];
          SupplementaryGroups = [ "systemd-journal" ];
        };
      };

      services.opentelemetry-collector = {
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
            
            # Transform processor to create environment and service labels
            transform = {
              metric_statements = [
                {
                  context = "datapoint";
                  statements = [
                    # Add environment label from service namespace
                    "set(attributes[\"environment\"], resource.attributes[\"service.namespace\"]) where resource.attributes[\"service.namespace\"] != nil"
                    # Add service label (keep service.name as-is)
                    "set(attributes[\"service\"], resource.attributes[\"service.name\"]) where resource.attributes[\"service.name\"] != nil"
                    # Add exported_job label for Grafana compatibility
                    "set(attributes[\"exported_job\"], Concat([resource.attributes[\"service.namespace\"], \"/\", resource.attributes[\"service.name\"]], \"\")) where resource.attributes[\"service.namespace\"] != nil and resource.attributes[\"service.name\"] != nil"
                  ];
                }
              ];
            };
          };

          exporters = {
            "otlphttp/betterstack" = {
              endpoint = "https://s1502393.eu-nbg-2.betterstackdata.com";
              headers.Authorization = "Bearer \${env:BETTERSTACK_TOKEN}";
            };
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
            extensions = [
              # TODO: Re-enable oidc extension when kube configuration is fixed
              # "oidc"
            ];
            pipelines = {
              "metrics/betterstack" = {
                receivers = [ "otlp" ];
                processors = [ "batch" "transform" ];
                exporters = [ "otlphttp/betterstack" ];
              };
              "metrics/prometheus" = {
                receivers = [ "otlp" ];
                processors = [ "batch" "transform" ];
                exporters = [ "prometheus" ];
              };
              "logs/betterstack" = {
                receivers = [ "otlp" ];
                processors = [ "batch" ];
                exporters = [ "otlphttp/betterstack" ];
              };
              "logs/loki" = {
                receivers = [ "otlp" "journald" ];
                processors = [ "batch" ];
                exporters = [ "loki" ];
              };
              "traces/betterstack" = {
                receivers = [ "otlp" ];
                processors = [ "batch" ];
                exporters = [ "otlphttp/betterstack" ];
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
    }

    # Traefik reverse proxy configuration
    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "otel-collector";
        port = 3333;
      };
    }
  ]);
}
