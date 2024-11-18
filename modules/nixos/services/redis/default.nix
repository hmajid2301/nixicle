{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.nixicle.redis;
in {
  options.services.nixicle.redis = {
    enable = mkEnableOption "Enable redis";
  };

  config = mkIf cfg.enable {
    services = {
      redis.servers = {
        main = {
          enable = true;
          port = 6380;
        };
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services.redis.loadBalancer.servers = [
              {
                url = "http://localhost:6380";
              }
            ];

            routers = {
              redis = {
                entryPoints = ["websecure"];
                rule = "Host(`redis.homelab.haseebmajid.dev`)";
                service = "redis";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
