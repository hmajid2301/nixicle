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
    services.tempo = {
      enable = true;
      settings = {
        server = {
          http_listen_port = 4400;
          grpc_listen_port = 4401;
        };
        distributor = {
          receivers = {
            otlp = {
              protocols = {
                http = {
                  endpoint = "0.0.0.0:4318";
                };
                grpc = {
                  endpoint = "0.0.0.0:4317";
                };
              };
            };
          };
        };
        storage = {
          trace = {
            backend = "local";
            local = {
              path = "/var/lib/tempo";
            };
            wal = {
              path = "/var/lib/tempo/wal";
            };
          };
        };
      };
    };

    # Configure tempo service with proper state directory
    systemd.services.tempo = {
      serviceConfig = {
        StateDirectory = "tempo";
        StateDirectoryMode = "0755";
      };
    };
  };
}
