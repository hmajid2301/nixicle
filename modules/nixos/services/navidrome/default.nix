{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.navidrome;
in {
  options.services.nixicle.navidrome = {
    enable = mkEnableOption "Enable the navidrome service";
  };

  config = mkIf cfg.enable {
    services = {
      navidrome = {
        enable = true;
        group = "media";
        settings = {
          MusicFolder = "/mnt/share/media/Music";
          ND_REVERSEPROXYUSERHEADER = "X-authentik-username";
          ND_REVERSEPROXYWHITELIST = "0.0.0.0/0";
        };
      };

      cloudflared = {
        enable = true;
        tunnels = {
          "ec0b6af0-a823-4616-a08b-b871fd2c7f58" = {
            ingress = {
              "navidrome.haseebmajid.dev" = {
                service = "https://localhost";
                originRequest = {
                  originServerName = "navidrome.haseebmajid.dev";
                };
              };
            };
          };
        };
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              navidrome.loadBalancer.servers = [
                {
                  url = "http://localhost:4533";
                }
              ];
            };

            routers = {
              navidrome = {
                entryPoints = ["websecure"];
                rule = "Host(`navidrome.haseebmajid.dev`)";
                service = "navidrome";
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
