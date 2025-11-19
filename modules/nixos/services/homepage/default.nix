# Homepage Dashboard Module
#
# This module configures the homepage dashboard service for homelab services.
# The configuration is split into separate files for maintainability:
# - services.nix: Service definitions grouped by category
# - widgets.nix: Widget configurations (search, resources, weather)
# - settings.nix: Dashboard settings and layout configuration
#
# Usage:
# ```nix
# services.nixicle.homepage.enable = true;
# ```
{ config, lib, ... }:
with lib;
let
  cfg = config.services.nixicle.homepage;
in
{
  options.services.nixicle.homepage = {
    enable = mkEnableOption "Enable homepage for homelab services";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      sops.secrets.homepage_env = {
        sopsFile = ../secrets.yaml;
      };

      services.homepage-dashboard = {
        enable = true;
        environmentFile = config.sops.secrets.homepage_env.path;
        listenPort = 8173;
        bookmarks = [ ];
        services = import ./services.nix.helper;
        settings = import ./settings.nix.helper;
        widgets = import ./widgets.nix.helper;
      };
    }

    # Traefik reverse proxy configuration
    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
        name = "homepage";
        port = 8173;
      };
    }
  ]);
}
