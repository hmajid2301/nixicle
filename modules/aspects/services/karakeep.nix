{ den, ... }:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
in
{
  den.aspects.karakeep = {
    nixos = { config, lib, ... }: {
      sops.secrets.karakeep_oauth.sopsFile = ../../../hosts/framebox/secrets.yaml;

      services.karakeep = {
        enable = true;
        browser.enable = true;
        extraEnvironment = {
          PORT = "3035";
          NEXTAUTH_URL = "https://karakeep.haseebmajid.dev";
          OAUTH_PROVIDER_NAME = "authentik";
          OAUTH_ALLOW_DANGEROUS_EMAIL_ACCOUNT_LINKING = "true";
          OAUTH_WELLKNOWN_URL = "https://authentik.haseebmajid.dev/application/o/karakeep/.well-known/openid-configuration";
          DISABLE_PASSWORD_AUTH = "true";
          DISABLE_SIGNUPS = "true";
          OLLAMA_BASE_URL = "http://localhost:11434";
          INFERENCE_TEXT_MODEL = "gemma2";
          INFERENCE_IMAGE_MODEL = "llava";
        };
        environmentFile = config.sops.secrets.karakeep_oauth.path;
      };

      services.cloudflared.tunnels.${tunnelId}.ingress."karakeep.haseebmajid.dev" = "http://localhost:3035";

      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "karakeep";
        port = 3035;
        subdomain = "karakeep";
        domain = "haseebmajid.dev";
      };

      environment.persistence."/persist".directories =
        lib.mkIf config.system.impermanence.enable [
          { directory = "/var/lib/karakeep"; user = "karakeep"; group = "karakeep"; mode = "0750"; }
        ];
    };
  };
}
