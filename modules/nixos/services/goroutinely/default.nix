{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.goroutinely;
in
{
  options.services.nixicle.goroutinely = {
    enable = mkEnableOption "Enable the goroutinely service";
  };

  config = mkIf cfg.enable {
    sops.secrets.goroutinely = {
      sopsFile = ../secrets.yaml;
    };

    services = {
      goroutinely = {
        enable = true;
        port = 8234;
        host = "0.0.0.0";
        database.createLocally = true;
        notifications = {
          enable = true;
          vapidSubject = "mailto:admin@haseebmajid.dev";
        };
        openFirewall = true;
        oauth = {
          skipAuth = false;
          jwksUrl = "https://authentik.haseebmajid.dev/application/o/go-routinely/.well-known/jwks.json";
          clientId = "goroutinely";
          authorizeUrl = "https://authentik.haseebmajid.dev/application/o/go-routinely/authorize/";
          tokenUrl = "https://authentik.haseebmajid.dev/application/o/go-routinely/token/";
        };
        secretsFile = config.sops.secrets.goroutinely.path;
      };

      cloudflared.tunnels = mkIf config.services.nixicle.cloudflare.enable {
        ${config.services.nixicle.cloudflare.tunnelId}.ingress = {
          "goroutinely.haseebmajid.dev" = "http://localhost:8234";
        };
      };

      traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "goroutinely";
        port = 8234;
        subdomain = "goroutinely";
        domain = "haseebmajid.dev";
      };
    };

    environment.persistence = mkIf config.system.impermanence.enable {
      "/persist" = {
        directories = [
          {
            directory = "/var/lib/goroutinely";
            user = "goroutinely";
            group = "goroutinely";
            mode = "0750";
          }
        ];
      };
    };
  };
}
