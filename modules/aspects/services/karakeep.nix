_: {
  den.aspects.karakeep = {
    persist.directories = [
      {
        directory = "/var/lib/karakeep";
        user = "karakeep";
        group = "karakeep";
        mode = "0750";
      }
    ];
    nixos =
      {
        config,
        lib,
        ...
      }:
      {
        system.backup.objects.karakeep.paths = [ "/var/lib/karakeep" ];
        sops.secrets.karakeep_oauth = { };
        services = {
          karakeep = {
            enable = true;
            browser.enable = true;
            extraEnvironment = {
              PORT = "3035";
              NEXTAUTH_URL = "https://karakeep.${config.nixicle.domains.root}";
              OAUTH_PROVIDER_NAME = "Pocket ID";
              OAUTH_ALLOW_DANGEROUS_EMAIL_ACCOUNT_LINKING = "true";
              OAUTH_WELLKNOWN_URL = "https://${config.nixicle.domains.sso}/.well-known/openid-configuration";
              DISABLE_PASSWORD_AUTH = "true";
              DISABLE_SIGNUPS = "false";
              OLLAMA_BASE_URL = "http://localhost:11434";
              INFERENCE_TEXT_MODEL = "glm-5.3-flash:cloud";
              INFERENCE_IMAGE_MODEL = "kimi-k2.6:cloud";
              INFERENCE_JOB_TIMEOUT_SEC = "120";
              INFERENCE_OUTPUT_SCHEMA = "json";
            };
            environmentFile = config.sops.secrets.karakeep_oauth.path;
          };

          traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
            name = "karakeep";
            port = 3035;
            subdomain = "karakeep";
            domain = config.nixicle.domains.root;
          };
        };

      };
  };
}
