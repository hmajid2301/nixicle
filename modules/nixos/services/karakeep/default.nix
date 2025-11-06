{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.karakeep;
in
{
  options.services.nixicle.karakeep = {
    enable = mkEnableOption "Enable the karakeep service";
  };

  config = mkIf cfg.enable {
    sops.secrets.karakeep_oauth = {
      sopsFile = ../secrets.yaml;
    };

    services = {
      karakeep = {
        enable = true;
        browser = {
          enable = true;
        };
        extraEnvironment = {
          PORT = "3035";
          NEXTAUTH_URL = "https://karakeep.haseebmajid.dev";
          OAUTH_PROVIDER_NAME = "authentik";
          OAUTH_ALLOW_DANGEROUS_EMAIL_ACCOUNT_LINKING = "true";
          OAUTH_WELLKNOWN_URL = "https://authentik.haseebmajid.dev/application/o/karakeep/.well-known/openid-configuration";
          DISABLE_PASSWORD_AUTH = "true";
          DISABLE_SIGNUPS = "true";
        };
        environmentFile = config.sops.secrets.karakeep_oauth.path;
      };

      cloudflared = {
        enable = true;
        tunnels = {
          "ec0b6af0-a823-4616-a08b-b871fd2c7f58" = {
            ingress = {
              "karakeep.haseebmajid.dev" = "http://localhost:3035";
            };
          };
        };
      };
    };
  };
}
