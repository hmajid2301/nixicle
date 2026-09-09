_: {
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
        config,
        pkgs,
        ...
      }:
      {
        services.opentelemetry-collector = {
          enable = true;
          package = pkgs.opentelemetry-collector-contrib;
          settings = {
            receivers = {
              otlp.protocols.http.endpoint = "0.0.0.0:3333";
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
              resource.attributes = [
                {
                  key = "host.name";
                  value = config.networking.hostName;
                  action = "insert";
                }
              ];
              batch = { };
              transform = { };
            };
            exporters = {
              "prometheus".endpoint = "127.0.0.1:8889";
              "otlphttp/loki".endpoint = "http://127.0.0.1:3030/otlp";
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
                  processors = [
                    "resource"
                    "batch"
                  ];
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

  den.aspects.otel-collector-forwarder = {
    includes = [ ];
    persist.directories = [ "/var/log/journal" ];

    nixos =
      {
        config,
        pkgs,
        ...
      }:
      {
        services.journald.settings.Journal.Storage = "persistent";

        services.opentelemetry-collector = {
          enable = true;
          package = pkgs.opentelemetry-collector-contrib;
          settings = {
            receivers = {
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
              resource.attributes = [
                {
                  key = "host.name";
                  value = config.networking.hostName;
                  action = "insert";
                }
              ];
              batch = { };
            };
            exporters."otlphttp/vps".endpoint = "http://vps:3333";
            service.pipelines."logs/vps" = {
              receivers = [ "journald" ];
              processors = [
                "resource"
                "batch"
              ];
              exporters = [ "otlphttp/vps" ];
            };
          };
        };
      };
  };
}
