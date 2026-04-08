{ den, ... }:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
in
{
  den.aspects.cloudflare = {
    nixos = { config, lib, ... }: {
      sops.secrets.cloudflared.sopsFile = ../../../hosts/framebox/secrets.yaml;

      services.cloudflared = {
        enable = true;
        tunnels.${tunnelId} = {
          credentialsFile = config.sops.secrets.cloudflared.path;
          default = "http_status:404";
          ingress = { };
        };
      };
    };
  };
}
