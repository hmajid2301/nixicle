{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.uptime-kuma;
in {
  options.services.nixicle.uptime-kuma = {
    enable = mkEnableOption "Enable uptime kuma";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services = {
        uptime-kuma = {
          enable = true;
          settings = {
            HOST = "0.0.0.0";
            PORT = "4000";
          };
        };

        cloudflared = {
          tunnels = {
            "0e845de6-544a-47f2-a1d5-c76be02ce153" = {
              ingress = {
                "uptime.haseebmajid.dev" = "http://localhost:4000";
              };
            };
          };
        };
      };
    }

    # Traefik reverse proxy configuration
    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
        name = "uptime-kuma";
        port = 4000;
        subdomain = "uptime";
      };
    }
  ]);
}
