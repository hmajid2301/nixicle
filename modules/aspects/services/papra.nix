{ ... }:
let
  domain = "papra.haseebmajid.dev";
  port = 1221;
in
{
  den.aspects.papra = {
    includes = [ ];
    backup.papra.paths = [ "/var/lib/papra" ];
    persist.directories = [
      {
        directory = "/var/lib/papra";
        user = "papra";
        group = "papra";
        mode = "0750";
      }
    ];
    nixos =
      { config, lib, ... }:
      {
        sops.secrets.papra-env = {
          restartUnits = [ "papra.service" ];
        };

        services.papra = {
          enable = true;
          environmentFile = config.sops.secrets.papra-env.path;
          environment = {
            APP_BASE_URL = "https://${domain}";
            NODE_ENV = "production";
            SERVER_HOSTNAME = "0.0.0.0";
            DOCUMENT_STORAGE_ENCRYPTION_IS_ENABLED = "true";
            AUTH_PROVIDERS_EMAIL_IS_ENABLED = "false";
          };
        };

        services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
          name = "papra";
          port = port;
          subdomain = "papra";
          domain = "haseebmajid.dev";
        };
      };
  };
}
