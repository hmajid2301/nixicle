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
        services = import ../../../data/homepage/services.nix;
        settings = import ../../../data/homepage/settings.nix;
        widgets = import ../../../data/homepage/widgets.nix;
      };

      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
        name = "homepage";
        port = 8173;
      };
    };
  };
}
