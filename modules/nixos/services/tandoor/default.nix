{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.tandoor;
in
{
  options.services.nixicle.tandoor = {
    enable = mkEnableOption "Enable the tandoor recipe service";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      sops.secrets.tandoor = {
        sopsFile = ../secrets.yaml;
      };

      systemd.services.tandoor-recipes = {
        serviceConfig = {
          EnvironmentFile = [ config.sops.secrets.tandoor.path ];
        };
        after = [ "postgresql.service" ];
      };

      users.users.nginx.extraGroups = [ "tandoor_recipes" ];

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
            MEDIA_URL = "https://tandoor-recipes-media.haseebmajid.dev/media/";
          };
        };

        postgresql = {
          ensureDatabases = [ "tandoor_recipes" ];
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

      environment.persistence = mkIf config.system.impermanence.enable {
        "/persist" = {
          directories = [
            {
              directory = "/var/lib/tandoor-recipes";
              user = "tandoor_recipes";
              group = "tandoor_recipes";
              mode = "0750";
            }
          ];
        };
      };
    }

    {
      services.cloudflared.tunnels = mkIf config.services.nixicle.cloudflare.enable {
        ${config.services.nixicle.cloudflare.tunnelId}.ingress = {
          "tandoor-recipes-media.haseebmajid.dev" = "http://localhost:8100";
          "tandoor-recipes.haseebmajid.dev" = "http://localhost:8099";
        };
      };
    }

    {
      services.traefik.dynamicConfigOptions.http = mkMerge [
        (lib.nixicle.mkTraefikService {
          name = "tandoor";
          port = 8099;
          subdomain = "tandoor-recipes";
          domain = "haseebmajid.dev";
        })
        {
          services.tandoor-media.loadBalancer.servers = [
            { url = "http://localhost:8100"; }
          ];
          routers.tandoor-media = {
            entryPoints = [ "websecure" ];
            rule = "Host(`tandoor-recipes-media.haseebmajid.dev`) && PathPrefix(`/media/`)";
            service = "tandoor-media";
            priority = 100;
            tls.certResolver = "letsencrypt";
          };
        }
      ];
    }
  ]);
}
