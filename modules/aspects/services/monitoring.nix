{ den, ... }:
{
  den.aspects.monitoring = {
    nixos = { ... }: {
      imports = [
        ../../../old/modules/nixos/services/monitoring/prometheus.nix
        ../../../old/modules/nixos/services/monitoring/scrape-configs.nix
        ../../../old/modules/nixos/services/monitoring/alertmanager.nix
        ../../../old/modules/nixos/services/monitoring/grafana.nix
        ../../../old/modules/nixos/services/monitoring/loki.nix
        ../../../old/modules/nixos/services/monitoring/tempo.nix
        ../../../old/modules/nixos/services/monitoring/traefik.nix
      ];
    };
  };
}
