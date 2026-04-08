{ den, ... }:
{
  den.aspects.homepage = {
    nixos = { config, lib, ... }: {
      sops.secrets.homepage_env.sopsFile = ../../../../hosts/framebox/secrets.yaml;

      services.homepage-dashboard = {
        enable = true;
        environmentFile = config.sops.secrets.homepage_env.path;
        listenPort = 8173;
        bookmarks = [ ];
        services = import ./services.nix;
        settings = import ./settings.nix;
        widgets = import ./widgets.nix;
      };

      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
        name = "homepage";
        port = 8173;
      };
    };
  };
}
