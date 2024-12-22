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

  config = mkIf cfg.enable {
    services.uptime-kuma = {
      enable = true;
      settings = {
        HOST = "0.0.0.0";
        PORT = "4000";
      };
    };

    services.traefik = {
      dynamicConfigOptions = {
        http = {
          services = {
            uptime-kuma.loadBalancer.servers = [
              {
                url = "http://localhost:4000";
              }
            ];
          };

          routers = {
            uptime-kuma = {
              entryPoints = ["websecure"];
              rule = "Host(`uptime.homelab.haseebmajid.dev`)";
              service = "uptime-kuma";
              tls.certResolver = "letsencrypt";
            };
          };
        };
      };
    };
  };
}
