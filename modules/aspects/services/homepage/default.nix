{ ... }:
{
  den.aspects.homepage = {
    nixos =
      { config, lib, ... }:
      {
        sops.secrets.homepage_env.sopsFile = ../../../../hosts/framebox/secrets.yaml;
        services.homepage-dashboard = {
          enable = true;
          environmentFiles = [ config.sops.secrets.homepage_env.path ];
          listenPort = 8173;
          bookmarks = [ ];
          services = import ./_services.nix;
          settings = import ./_settings.nix;
          widgets = import ./_widgets.nix;
        };

        services.traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
          name = "homepage";
          port = 8173;
        };
      };
  };
}
