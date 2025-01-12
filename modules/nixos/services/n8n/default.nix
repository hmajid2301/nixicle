{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.n8n;
in {
  options.services.nixicle.n8n = {
    enable = mkEnableOption "Enable n8n";
  };

  config = mkIf cfg.enable {
    services = {
      n8n = {
        enable = true;
        openFirewall = true;
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services.n8n.loadBalancer.servers = [
              {
                url = "http://localhost:5678";
              }
            ];

            routers = {
              n8n = {
                entryPoints = ["websecure"];
                rule = "Host(`n8n.homelab.haseebmajid.dev`)";
                service = "n8n";
                tls.certResolver = "letsencrypt";
                middlewares = ["authentik"];
              };
            };
          };
        };
      };
    };
  };
}
