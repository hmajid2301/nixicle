_: {
  den.aspects.homepage = {
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
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
              environmentFiles = [ config.sops.secrets.homepage_env.path ];
              listenPort = 8173;
              allowedHosts = "homepage.${config.nixicle.domains.root},localhost:8173,127.0.0.1:8173";
              bookmarks = [ ];
              services = import ./_services.nix { inherit config lib; };
              settings = import ./_settings.nix { inherit lib; };
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
                domain = config.nixicle.domains.root;
              })
              (lib.nixicle.mkTraefikService {
                name = "homepage-icons";
                port = 8174;
                subdomain = "homepage";
                domain = config.nixicle.domains.root;
                extraRouterConfig.rule = "Host(`homepage.${config.nixicle.domains.root}`) && PathPrefix(`/icons`)";
              })
            ];
          };
        };
      };
  };
}
