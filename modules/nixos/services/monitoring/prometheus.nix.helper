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
    sops.secrets = {
      home_assistant_token = {
        sopsFile = ../secrets.yaml;
      };

      minio_prometheus_bearer_token = {
        sopsFile = ../secrets.yaml;
      };
    };

    services.prometheus = {
      port = 3020;
      enable = true;
      checkConfig = "syntax-only";
      extraFlags = [
        "--web.enable-admin-api"
        "--storage.tsdb.retention.time=30d"
      ];

      exporters = {
        redis = {
          enable = true;
        };

        postgres = {
          enable = true;
        };

        node = {
          port = 3021;
          enabledCollectors = [ "systemd" ];
          enable = true;
        };
      };
    };
  };
}
