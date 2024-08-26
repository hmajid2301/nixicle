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
    enable = mkEnableOption "Enable the tandoor recipe service";
  };

  config = mkIf cfg.enable {
    sops.secrets.tandoor = {
      sopsFile = ../secrets.yaml;
    };

    systemd.services.tandoor-recipes = {
      serviceConfig = {
        EnvironmentFile = [config.sops.secrets.tandoor.path];
      };
      after = ["postgresql.service"];
    };

    services = {
      tandoor-recipes = {
        enable = true;
        port = 8099;
        extraConfig = {
          DB_ENGINE = "django.db.backends.postgresql";
          POSTGRES_HOST = "/run/postgresql";
          POSTGRES_USER = "tandoor_recipes";
          POSTGRES_DB = "tandoor_recipes";
          SOCIAL_DEFAULT_GROUP = "user";
          SOCIAL_PROVIDERS = "allauth.socialaccount.providers.openid_connect";
        };
      };

      postgresql = {
        ensureDatabases = ["tandoor_recipes"];
        ensureUsers = [
          {
            name = "tandoor_recipes";
            ensureDBOwnership = true;
          }
        ];
      };

      nginx = {
        enable = true;
        virtualHosts = {
          "recipes-media" = {
            listen = [
              {
                addr = "localhost";
                port = 8100;
              }
            ];
            locations = {
              "/media/" = {
                alias = "/var/lib/tandoor-recipes/";
              };
            };
          };
        };
      };
    };
  };
}
