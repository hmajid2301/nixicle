{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.tandoor;
in {
  options.services.tandoor = {
    enable = mkEnableOption "Enable The recipe management service";
  };

  config = mkIf cfg.enable {
    services = {
      tandoor-recipes = {
        enable = true;
        port = 8099;
      };
      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              recipes.loadBalancer.servers = [
                {
                  url = "http://localhost:8099";
                }
              ];
            };

            routers = {
              recipes = {
                entryPoints = ["websecure"];
                rule = "Host(`recipes.bare.homelab.haseebmajid.dev`)";
                service = "recipes";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
