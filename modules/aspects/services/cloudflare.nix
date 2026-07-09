{ ... }:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
in
{
  den.aspects.cloudflare = {
    nixos =
      { config, secrets, lib, ... }:
      let
        secretPaths = lib.mergeAttrsList secrets;
      in
      {
        sops.secrets.cloudflared = { };
        services.cloudflared = {
          enable = true;
          tunnels.${tunnelId} = {
            credentialsFile = secretPaths.cloudflared;
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
