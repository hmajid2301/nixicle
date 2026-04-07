{ den, ... }:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
in
{
  den.aspects.gotify = {
    nixos = { lib, ... }: {
      services = {
        gotify = {
          enable = true;
          environment.GOTIFY_SERVER_PORT = "8051";
        };

        traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
          name = "notify";
          port = 8051;
        };

        cloudflared.tunnels.${tunnelId}.ingress."notify.haseebmajid.dev" = "http://localhost:8051";
      };
    };
  };
}
