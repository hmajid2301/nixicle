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

  config = mkIf cfg.enable {
    sops.secrets.betterstack_token = {
      sopsFile = ../secrets.yaml;
    };

    systemd.services.opentelemetry-collector = {
      serviceConfig = {
        EnvironmentFile = [ config.sops.secrets.betterstack_token.path ];
      };
    };

    services = {
      opentelemetry-collector = {
        enable = true;
        package = pkgs.opentelemetry-collector-contrib;
        settings = {
          receivers = {
            otlp.protocols.http.endpoint = "0.0.0.0:3333";
            otlp.protocols.grpc.endpoint = "0.0.0.0:3334";
          };
          processors.batch = { };
          exporters = {
            "otlphttp/betterstack" = {
              endpoint = "https://s1502393.eu-nbg-2.betterstackdata.com";
              headers.Authorization = "Bearer \${env:BETTERSTACK_TOKEN}";
            };
          };
          service = {
            telemetry.metrics.address = "0.0.0.0:8899";
            pipelines = {
              "metrics/betterstack" = {
                receivers = [
                  "otlp"
                ];
                processors = [ "batch" ];
                exporters = [ "otlphttp/betterstack" ];
              };
              "logs/betterstack" = {
                receivers = [ "otlp" ];
                processors = [ "batch" ];
                exporters = [ "otlphttp/betterstack" ];
              };
              "traces/betterstack" = {
                receivers = [ "otlp" ];
                processors = [ "batch" ];
                exporters = [ "otlphttp/betterstack" ];
              };
            };
          };
        };
      };

      cloudflared = {
        tunnels = {
          "0e845de6-544a-47f2-a1d5-c76be02ce153" = {
            ingress = {
              "otel-collector.haseebmajid.dev" = "http://localhost:3333";
            };
          };
        };
      };
    };
  };
}
