{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.cloudflare;
in
{
  options.services.nixicle.cloudflare = with types; {
    enable = mkBoolOpt false "Whether to enable Cloudflare tunnel.";
    tunnelId = mkOpt str "" "The Cloudflare tunnel ID.";
    credentialsFile = mkOpt str "" "Path to the tunnel credentials file.";
    defaultRoute = mkOpt str "http_status:404" "Default route for unmatched requests.";
  };

  config = mkIf cfg.enable {
    services.cloudflared = {
      enable = true;
      tunnels.${cfg.tunnelId} = {
        credentialsFile = cfg.credentialsFile;
        default = cfg.defaultRoute;
        # Individual services will add their ingress rules via lib.mkMerge
        ingress = {};
      };
    };
  };
}