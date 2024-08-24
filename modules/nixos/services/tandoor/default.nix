{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.tandoor;
in {
  options.services.tandoor = {
    enable = mkEnableOption "Enable The recipe management service";
  };

  config = mkIf cfg.enable {
    sops.secrets.tandoor = {
      sopsFile = ../secrets.yaml;
    };

    systemd.services.tandoor-recipes = {
      serviceConfig = {
        EnvironmentFile = [config.sops.secrets.tandoor.path];
      };
    };

    services = {
      tandoor-recipes = {
        enable = true;
        port = 8099;
        extraConfig = {
          # DATABASE_URL = "postgresql://tandoor@localhost/tandoor";
          REMOTE_USER_AUTH = "1";
          SOCIAL_DEFAULT_ACCESS = "1";
          SOCIAL_DEFAULT_GROUP = "guest";
          SOCIAL_PROVIDERS = "allauth.socialaccount.providers.openid_connect";
        };
      };

      postgresql = {
        ensureDatabases = ["tandoor"];
        ensureUsers = [
          {
            name = "tandoor";
            ensureDBOwnership = true;
          }
        ];
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              recipes.loadBalancer.servers = [
                {
                  url = "http://localhost:8099";
                }
              ];
            };

            routers = {
              recipes = {
                entryPoints = ["websecure"];
                rule = "Host(`recipes.bare.homelab.haseebmajid.dev`)";
                service = "recipes";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
