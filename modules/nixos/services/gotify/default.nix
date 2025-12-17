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
      services.gotify = {
        enable = true;
        environment = {
          GOTIFY_SERVER_PORT = "8051";
        };
      };
    }

    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "notify";
        port = 8051;
      };
    }

    {
      services.cloudflared.tunnels = mkIf config.services.nixicle.cloudflare.enable {
        ${config.services.nixicle.cloudflare.tunnelId}.ingress = {
          "notify.haseebmajid.dev" = "http://localhost:8051";
        };
      };
    }
  ]);
}
