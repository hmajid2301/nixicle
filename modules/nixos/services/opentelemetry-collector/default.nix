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

    sops.templates."otel_env" = {
      content = ''
        BETTERSTACK_TOKEN=${config.sops.placeholder.otel_betterstack_token}
      '';
    };

    systemd.services.opentelemetry-collector = {
      serviceConfig = {
        EnvironmentFile = config.sops.templates."otel_env".path;
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
              # TODO: Re-enable auth when kube configuration is fixed
              # auth.authenticator = "oidc";
            };
          };
          processors.batch = { };
          extensions = {
            # TODO: Re-enable oidc extension when kube configuration is fixed
            # oidc = {
            #   issuer_url = "https://authentik.haseebmajid.dev/application/o/otel-collector/";
            #   audience = "otel-collector";
            #   username_claim = "email";
            # };
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
              endpoint = "http://127.0.0.1:4400/v1/traces";
            };
          };
          service = {
            telemetry = {
              metrics.level = "none";
            };
            extensions = [ 
              # TODO: Re-enable oidc extension when kube configuration is fixed
              # "oidc" 
            ];
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
                exporters = [ "otlphttp/tempo" ];
              };
            };
          };
        };
      };


    };
  };
}
