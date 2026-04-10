{ ... }:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
in
{
  den.aspects.audiobookshelf = {
    nixos = _: {
      services.audiobookshelf = {
        enable = true;
        port = 8555;
        group = "media";
      };

      services.cloudflared.tunnels.${tunnelId}.ingress."audiobookshelf.haseebmajid.dev" =
        "http://localhost:8555";
    };
  };
}
