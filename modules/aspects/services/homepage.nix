{ den, ... }:
{
  den.aspects.homepage = {
    nixos = { config, lib, ... }: {
      sops.secrets.homepage_env.sopsFile = ../../../hosts/framebox/secrets.yaml;

      services.homepage-dashboard = {
        enable = true;
        environmentFile = config.sops.secrets.homepage_env.path;
        listenPort = 8173;
        bookmarks = [ ];
        services = import ../../../old/modules/nixos/services/homepage/services.nix;
        settings = import ../../../old/modules/nixos/services/homepage/settings.nix;
        widgets = import ../../../old/modules/nixos/services/homepage/widgets.nix;
      };

      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
        name = "homepage";
        port = 8173;
      };
    };
  };
}
