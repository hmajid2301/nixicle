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
    sops.secrets = {
      otel_betterstack_token = {
        sopsFile = ../secrets.yaml;
      };
      otel_client_id = {
        sopsFile = ../secrets.yaml;
      };
      otel_client_secret = {
        sopsFile = ../secrets.yaml;
      };
    };

    systemd.services.opentelemetry-collector = {
      serviceConfig = {
        EnvironmentFile = [
          config.sops.secrets.otel_betterstack_token.path
          config.sops.secrets.otel_client_id.path
          config.sops.secrets.otel_client_secret.path
        ];
      };
    };

    services = {
      opentelemetry-collector = {
        enable = true;
        package = pkgs.opentelemetry-collector-contrib;
        settings = {
          receivers = {
            otlp.protocols.http = {
              endpoint = "0.0.0.0:3333";
              auth.authenticator = "oidc";
            };
            otlp.protocols.grpc = {
              endpoint = "0.0.0.0:3334";
              auth.authenticator = "oidc";
            };
          };
          processors.batch = { };
          extensions = {
            oidc = {
              issuer_url = "https://authentik.haseebmajid.dev/application/o/otel-collector/";
              audience = "otel-collector";
              client_id = "\${env:OTEL_CLIENT_ID}";
              client_secret = "\${env:OTEL_CLIENT_SECRET}";
              username_claim = "email";
            };
          };
          exporters = {
            "otlphttp/betterstack" = {
              endpoint = "https://s1502393.eu-nbg-2.betterstackdata.com";
              headers.Authorization = "Bearer \${env:BETTERSTACK_TOKEN}";
            };
            "prometheus" = {
              endpoint = "http://127.0.0.1:3020";
            };
            "loki" = {
              endpoint = "http://127.0.0.1:3030/loki/api/v1/push";
            };
            "otlp/tempo" = {
              endpoint = "http://127.0.0.1:4400";
              tls.insecure = true;
            };
          };
          service = {
            telemetry.metrics.address = "0.0.0.0:8899";
            extensions = [ "oidc" ];
            pipelines = {
              "metrics/betterstack" = {
                receivers = [ "otlp" ];
                processors = [ "batch" ];
                exporters = [ "otlphttp/betterstack" ];
              };
              "metrics/prometheus" = {
                receivers = [ "otlp" ];
                processors = [ "batch" ];
                exporters = [ "prometheus" ];
              };
              "logs/betterstack" = {
                receivers = [ "otlp" ];
                processors = [ "batch" ];
                exporters = [ "otlphttp/betterstack" ];
              };
              "logs/loki" = {
                receivers = [ "otlp" ];
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
                exporters = [ "otlp/tempo" ];
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
