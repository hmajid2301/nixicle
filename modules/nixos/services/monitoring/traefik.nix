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
      (config.lib.traefik.mkTraefikService {
        name = "prometheus";
        port = 3020;
      })

      # Grafana - visualization dashboard
      (config.lib.traefik.mkTraefikService {
        name = "grafana";
        port = 3010;
      })

      # Alertmanager - alert handling
      (config.lib.traefik.mkTraefikService {
        name = "alertmanager";
        port = 9093;
      })

      # Tempo - distributed tracing
      (config.lib.traefik.mkTraefikService {
        name = "tempo";
        port = 4400;
      })
    ];
  };
}
