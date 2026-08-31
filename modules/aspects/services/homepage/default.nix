_: {
  den.aspects.homepage = {
    nixos =
      {
        config,
        lib,
        pkgs,
        secrets,
        ...
      }:
      let
        secretPaths = lib.mergeAttrsList secrets;
        theme = import ./_theme.nix { };
        cfg = config.nixicle.homepage;
        variant = theme.${cfg.themeVariant} or theme.crt;
        iconSet = import ./_service-icons.nix { inherit lib pkgs; };
      in
      {
        options.nixicle.homepage = {
          themeVariant = lib.mkOption {
            type = lib.types.enum [ "catppuccin" ];
            default = "catppuccin";
            description = "Retro pixel theme variant for homepage-dashboard.";
          };
        };

        config = {
          sops.secrets.homepage_env = { };

          services = {
            homepage-dashboard = {
              enable = true;
              environmentFiles = [ secretPaths.homepage_env ];
              listenPort = 8173;
              allowedHosts = "homepage.haseebmajid.dev,localhost:8173,127.0.0.1:8173";
              bookmarks = [ ];
              services = import ./_services.nix { inherit config lib; };
              settings = import ./_settings.nix;
              widgets = import ./_widgets.nix;
              customCSS = variant;
              customJS = builtins.readFile ./custom.js;
            };

            nginx = {
              enable = true;
              virtualHosts."homepage-icons" = {
                listen = [
                  {
                    addr = "localhost";
                    port = 8174;
                  }
                ];
                root = "${iconSet.iconsPackage}";
              };
            };

            traefik.dynamicConfigOptions.http = lib.mkMerge [
              (lib.nixicle.mkAuthenticatedTraefikService {
                name = "homepage";
                port = 8173;
                subdomain = "homepage";
                domain = "haseebmajid.dev";
              })
              (lib.nixicle.mkTraefikService {
                name = "homepage-icons";
                port = 8174;
                subdomain = "homepage";
                domain = "haseebmajid.dev";
                extraRouterConfig.rule = "Host(`homepage.haseebmajid.dev`) && PathPrefix(`/icons`)";
              })
            ];
          };
        };
      };
  };
}
