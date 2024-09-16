{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.immich;
in {
  options.services.nixicle.immich = {
    enable = mkEnableOption "Enable the immich photo service";
  };

  config = mkIf cfg.enable {
    services = {
      cloudflared = {
        tunnels = {
          "ec0b6af0-a823-4616-a08b-b871fd2c7f58" = {
            ingress = {
            };
          };
        };
      };

      # postgresql = {
      #   ensureDatabases = ["immich"];
      #   ensureUsers = [
      #     {
      #       name = "immich";
      #       ensureDBOwnership = true;
      #     }
      #   ];
      # };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              immich.loadBalancer.servers = [
                {
                  url = "http://localhost:2283";
                }
              ];
            };

            routers = {
              immich = {
                entryPoints = ["websecure"];
                rule = "Host(`immich.homelab.haseebmajid.dev`)";
                service = "immich";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
