{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.cloudflared;
in {
  options.services.nixicle.cloudflared = {
    enable = mkEnableOption "Enable The cloudflared (tunnel) service";
  };

  config = mkIf cfg.enable {
    sops.secrets.cloudflared = {
      sopsFile = ../secrets.yaml;
      owner = "cloudflared";
    };

    services = {
      cloudflared = {
        enable = true;
        tunnels = {
          "ec0b6af0-a823-4616-a08b-b871fd2c7f58" = {
            credentialsFile = config.sops.secrets.cloudflared.path;
            default = "http_status:404";
            # TODO: refactor these into where the services are defined like we do with traefik
            ingress = {
              "tandoor-recipes.haseebmajid.dev/media/" = "http://localhost:8100";
              "tandoor-recipes.haseebmajid.dev" = "http://localhost:8099";
              "authentik.haseebmajid.dev" = "http://localhost:9000";
              "paperless.haseebmajid.dev" = "http://localhost:28981";
              "jellyseerr.haseebmajid.dev" = "http://localhost:5055";
              "audiobookshelf.haseebmajid.dev" = "http://localhost:8555";
              "homepage.haseebmajid.dev" = "http://localhost:8173";
            };
          };
        };
      };
    };
  };
}
