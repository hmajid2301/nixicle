# Traefik reverse proxy configuration for monitoring services
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
    services.traefik.dynamicConfigOptions.http = mkMerge [
      # Prometheus - metrics collection
      (lib.nixicle.mkTraefikService {
        name = "prometheus";
        port = 3020;
      })

      # Grafana - visualization dashboard
      (lib.nixicle.mkTraefikService {
        name = "grafana";
        port = 3010;
      })

      # Alertmanager - alert handling
      (lib.nixicle.mkTraefikService {
        name = "alertmanager";
        port = 9093;
      })

      # Tempo - distributed tracing
      (lib.nixicle.mkTraefikService {
        name = "tempo";
        port = 4400;
      })
    ];
  };
}
