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

    environment.persistence = mkIf config.system.impermanence.enable {
      "/persist" = {
        directories = [
          { directory = "/var/lib/prometheus2"; mode = "0755"; }
        ];
      };
    };
  };
}
