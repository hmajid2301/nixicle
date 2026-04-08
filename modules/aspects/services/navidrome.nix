{ den, ... }:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
in
{
  den.aspects.navidrome = {
    nixos = { lib, ... }: {
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

        traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
          name = "navidrome";
          port = 4533;
          domain = "haseebmajid.dev";
        };

        cloudflared.tunnels.${tunnelId}.ingress."navidrome.haseebmajid.dev" = {
          service = "https://localhost";
          originRequest.originServerName = "navidrome.haseebmajid.dev";
        };
      };
    };
  };
}
