{ config, lib, ... }:
with lib;
let cfg = config.services.nixicle.navidrome;
in {
  options.services.nixicle.navidrome = {
    enable = mkEnableOption "Enable the navidrome service";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services = {
        navidrome = {
          enable = true;
          group = "media";
          settings = {
            MusicFolder = "/mnt/n1/media/Music";
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
      };
    }

    # Traefik reverse proxy configuration
    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
        name = "navidrome";
        port = 4533;
        domain = "haseebmajid.dev";
      };
    }
  ]);
}
