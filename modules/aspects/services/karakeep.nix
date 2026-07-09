{ ... }:
{
  den.aspects.karakeep = {
    includes = [ ];
    persist.directories = [
      {
        directory = "/var/lib/karakeep";
        user = "karakeep";
        group = "karakeep";
        mode = "0750";
      }
    ];
    nixos =
      { config, lib, ... }:
      {
        sops.secrets.karakeep_oauth = { };
        services = {
          karakeep = {
            enable = true;
            browser.enable = true;
            extraEnvironment = {
              PORT = "3035";
              NEXTAUTH_URL = "https://karakeep.haseebmajid.dev";
              OAUTH_PROVIDER_NAME = "Pocket ID";
              OAUTH_ALLOW_DANGEROUS_EMAIL_ACCOUNT_LINKING = "true";
              OAUTH_WELLKNOWN_URL = "https://id.haseebmajid.dev/.well-known/openid-configuration";
              DISABLE_PASSWORD_AUTH = "true";
              DISABLE_SIGNUPS = "false";
              OLLAMA_BASE_URL = "http://localhost:11434";
              INFERENCE_TEXT_MODEL = "gemma2";
              INFERENCE_IMAGE_MODEL = "llava";
            };
            environmentFile = config.sops.secrets.karakeep_oauth.path;
          };

          traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
            name = "karakeep";
            port = 3035;
            subdomain = "karakeep";
            domain = "haseebmajid.dev";
          };
        };

      };
  };
}
