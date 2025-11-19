{
  config,
  lib,
  ...
}:
with lib;
 let
  cfg = config.services.nixicle.gotify;
in {
  options.services.nixicle.gotify = {
    enable = mkEnableOption "Enable the notify service";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services = {
        gotify = {
          enable = true;
          environment = {
            GOTIFY_SERVER_PORT = "8051";
          };
        };

        cloudflared = {
          tunnels = {
            "0e845de6-544a-47f2-a1d5-c76be02ce153" = {
              ingress = {
                "notify.haseebmajid.dev" = "http://localhost:8051";
              };
            };
          };
        };
      };
    }

    # Traefik reverse proxy configuration
    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "notify";
        port = 8051;
      };
    }
  ]);
}
