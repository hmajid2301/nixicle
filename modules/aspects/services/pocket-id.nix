{ den, ... }:
{
  den.aspects.pocketid = {
    includes = [ den.aspects.postgresql ];
    persist.directories = [
      {
        directory = "/var/lib/pocket-id";
        user = "pocketid";
        group = "pocketid";
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
        sops.secrets = {
          pocketid_encryption_key = {
            owner = config.services.pocket-id.user;
            inherit (config.services.pocket-id) group;
            mode = "0400";
          };
          pocketid_static_api_key = {
            owner = config.services.pocket-id.user;
            inherit (config.services.pocket-id) group;
            mode = "0400";
          };
        };

        users.users.pocketid = {
          isSystemUser = true;
          group = "pocketid";
          home = "/var/lib/pocket-id";
          createHome = true;
        };
        users.groups.pocketid = { };

        services.postgresql = {
          ensureDatabases = [ "pocketid" ];
          ensureUsers = [
            {
              name = "pocketid";
              ensureDBOwnership = true;
            }
          ];
        };

        services.pocket-id = {
          enable = true;
          user = "pocketid";
          group = "pocketid";
          settings = {
            APP_URL = "https://id.haseebmajid.dev";
            TRUST_PROXY = true;
            HOST = "127.0.0.1";
            PORT = 1411;
            DB_CONNECTION_STRING = "postgres://pocketid@/pocketid?host=/run/postgresql";
            UI_CONFIG_DISABLED = true;
            ALLOW_USER_SIGNUPS = "disabled";
            ANALYTICS_DISABLED = true;
            VERSION_CHECK_DISABLED = true;
          };
          credentials = {
            ENCRYPTION_KEY = config.sops.secrets.pocketid_encryption_key.path;
            STATIC_API_KEY = config.sops.secrets.pocketid_static_api_key.path;
          };
        };

        services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
          name = "pocket-id";
          port = 1411;
          subdomain = "id";
          domain = "haseebmajid.dev";
        };
      };
  };
}
