{ ... }:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
in
{
  den.aspects.cloudflare = {
    nixos =
      { config, ... }:
      {
        sops.secrets.cloudflared.sopsFile = ../../../hosts/framebox/secrets.yaml;
        services.cloudflared = {
          enable = true;
          tunnels.${tunnelId} = {
            credentialsFile = config.sops.secrets.cloudflared.path;
            default = "http_status:404";
            ingress = { };
          };
        };

        # Force HTTP2 (TCP) instead of QUIC (UDP) — more stable through consumer router/WiFi
        systemd.services."cloudflared-tunnel-${tunnelId}".environment.TUNNEL_TRANSPORT_PROTOCOL =
          "http2";
      };
  };
}
