# Monitoring Stack Module
#
# This module provides a comprehensive monitoring solution including:
# - Prometheus: Metrics collection and storage
# - Grafana: Visualization and dashboards with OAuth authentication
# - Alertmanager: Alert routing and management
# - Tempo: Distributed tracing
# - Traefik: Reverse proxy routing for all services
#
# The module has been split into focused files for better maintainability:
# - prometheus.nix: Prometheus service and exporters configuration
# - scrape-configs.nix: Prometheus scrape job definitions
# - alertmanager.nix: Alertmanager configuration
# - grafana.nix: Grafana service, OAuth, and datasource provisioning
# - tempo.nix: Tempo distributed tracing configuration
# - traefik.nix: Traefik routing rules for monitoring services

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
  imports = [
    ./prometheus.nix
    ./scrape-configs.nix
    ./alertmanager.nix
    ./grafana.nix
    ./tempo.nix
    ./traefik.nix
  ];

  options.services.nixicle.monitoring = {
    enable = mkEnableOption "Enable The monitoring stack(loki, prometheus, grafana)";
  };
}
