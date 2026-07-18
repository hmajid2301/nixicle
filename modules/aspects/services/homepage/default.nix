{ ... }:
{
  den.aspects.homepage = {
    nixos =
      {
        config,
        lib,
        secrets,
        ...
      }:
      let
        secretPaths = lib.mergeAttrsList secrets;
      in
      {
        sops.secrets.homepage_env = { };
        services.homepage-dashboard = {
          enable = true;
          environmentFiles = [ secretPaths.homepage_env ];
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
