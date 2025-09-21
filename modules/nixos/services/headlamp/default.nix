{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.headlamp;
in
{
  options.services.nixicle.headlamp = {
    enable = mkEnableOption "Enable Headlamp Kubernetes dashboard with Traefik ingress";
  };

  config = mkIf cfg.enable {
    services = {
      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              headlamp.loadBalancer.servers = [
                {
                  url = "http://localhost:30080";
                }
              ];
            };

            routers = {
              headlamp = {
                entryPoints = [ "websecure" ];
                rule = "Host(`headlamp.homelab.haseebmajid.dev`)";
                service = "headlamp";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}