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

    {
      services.cloudflared.tunnels = mkIf config.services.nixicle.cloudflare.enable {
        ${config.services.nixicle.cloudflare.tunnelId}.ingress = {
          "navidrome.haseebmajid.dev" = {
            service = "https://localhost";
            originRequest = {
              originServerName = "navidrome.haseebmajid.dev";
            };
          };
        };
      };
    }
  ]);
}
