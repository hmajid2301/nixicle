_: {
  den.aspects.tandoor = {
    includes = [ ];
    backup.tandoor.paths = [ "/var/lib/tandoor-recipes" ];
    persist.directories = [
      {
        directory = "/var/lib/tandoor-recipes";
        user = "tandoor_recipes";
        group = "tandoor_recipes";
        mode = "0750";
      }
    ];
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        sops.secrets.tandoor = { };
        systemd.services.tandoor-recipes = {
          serviceConfig.EnvironmentFile = [ config.sops.secrets.tandoor.path ];
          after = [ "postgresql.service" ];
        };

        users.users.nginx.extraGroups = [ "tandoor_recipes" ];

        services = {
          tandoor-recipes = {
            enable = true;
            port = 8099;
            # Upstream calls json.loads(response_text) directly on LLM output, which
            # fails when the model wraps JSON in markdown code fences (```json ... ```).
            # kimi-k2.6 and many other Ollama models do this despite response_format
            # json_object. Strip fences before parsing. See cookbook/views/api.py
            # sites: json.loads(response_text) (4 occurrences).
            package = pkgs.tandoor-recipes.overrideAttrs (old: {
              postPatch = (old.postPatch or "") + ''
                                  substituteInPlace cookbook/views/api.py \
                                    --replace-fail "import traceback" "import traceback


                def _ai_strip_fences(text):
                    if not isinstance(text, str):
                        return text
                    s = text.strip()
                    fence = chr(96) * 3
                    if s.startswith(fence):
                        s = s[3:]
                        if s[:4].lower() == 'json':
                            s = s[4:]
                        s = s.lstrip()
                    if s.endswith(fence):
                        s = s[:-3].rstrip()
                    return s"
                                  substituteInPlace cookbook/views/api.py \
                                    --replace-fail "json.loads(response_text)" "json.loads(_ai_strip_fences(response_text))"
              '';
            });
            extraConfig = {
              ALLOWED_HOSTS = "tandoor-recipes.haseebmajid.dev,localhost,127.0.0.1";
              DB_ENGINE = "django.db.backends.postgresql";
              POSTGRES_HOST = "/run/postgresql";
              POSTGRES_USER = "tandoor_recipes";
              POSTGRES_DB = "tandoor_recipes";
              SOCIAL_DEFAULT_GROUP = "user";
              SOCIAL_PROVIDERS = "allauth.socialaccount.providers.openid_connect";
              MEDIA_URL = "https://tandoor-recipes-media.haseebmajid.dev/media/";
              MEDIA_ROOT = "/var/lib/tandoor-recipes/";
              SPACE_AI_ENABLED = "1";
              SPACE_AI_CREDITS_MONTHLY = "1000";
              AI_RATELIMIT = "600/hour";
              AI_ALLOWED_URLS = "http://localhost:11434";
              # INFO: AI can take more than 30s; --timeout in CMD_ARGS is reliably applied (env GUNICORN_TIMEOUT alone is not)
              GUNICORN_CMD_ARGS = "--bind=localhost:8099 --timeout 300";
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
            virtualHosts."recipes-media" = {
              listen = [
                {
                  addr = "localhost";
                  port = 8100;
                }
              ];
              locations."/media/".alias = "/var/lib/tandoor-recipes/";
            };
          };

          traefik.dynamicConfigOptions.http = lib.mkMerge [
            (lib.nixicle.mkTraefikService {
              name = "tandoor";
              port = 8099;
              subdomain = "tandoor-recipes";
              domain = "haseebmajid.dev";
            })
            {
              services.tandoor-media.loadBalancer.servers = [ { url = "http://localhost:8100"; } ];
              routers.tandoor-media = {
                entryPoints = [ "websecure" ];
                rule = "Host(`tandoor-recipes-media.haseebmajid.dev`) && PathPrefix(`/media/`)";
                service = "tandoor-media";
                priority = 100;
                tls.certResolver = "letsencrypt";
              };
            }
          ];
        };
      };
  };
}
