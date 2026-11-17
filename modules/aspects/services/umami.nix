_: {
  den.aspects.umami.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      port = 3040;
      ssoPort = 3041;
      domain = config.nixicle.domains.root;
      host = "umami.${domain}";
      adminUuid = "41e2b680-648e-4b09-bcd7-3e2b10c06264";
      inherit (config.sops) placeholder;
    in
    {
      sops = {
        secrets = {
          umami_app_secret.restartUnits = [ "umami.service" ];
          umami_oidc_client_secret = { };
        };
        templates."umami-sso.env" = {
          content = ''
            UMAMI_APP_SECRET=${placeholder.umami_app_secret}
            UMAMI_OIDC_CLIENT_SECRET=${placeholder.umami_oidc_client_secret}
          '';
          restartUnits = [ "umami-sso.service" ];
        };
      };

      services = {
        umami = {
          enable = true;
          settings = {
            APP_SECRET_FILE = config.sops.secrets.umami_app_secret.path;
            HOSTNAME = "127.0.0.1";
            PORT = port;
            DISABLE_TELEMETRY = true;
          };
        };

        traefik.dynamicConfigOptions.http = lib.mkMerge [
          (lib.nixicle.mkTraefikService {
            name = "umami";
            inherit port domain;
          })
          (lib.nixicle.mkTraefikService {
            name = "umami-sso";
            port = ssoPort;
            extraRouterConfig.rule = "Host(`${host}`) && (PathPrefix(`/login`) || PathPrefix(`/logout`))";
          })
        ];
      };

      systemd.services = {
        umami-sso-users = {
          description = "Link the Umami admin to Pocket ID and disable password logins";
          after = [ "umami.service" ];
          requires = [ "umami.service" ];
          wantedBy = [ "multi-user.target" ];
          path = [ config.services.postgresql.package ];
          serviceConfig = {
            Type = "oneshot";
            User = "postgres";
          };
          script = ''
            for _ in $(seq 1 60); do
              psql -d umami -tAc "SELECT 1 FROM \"user\" WHERE user_id = '${adminUuid}'" | grep -q 1 && break
              sleep 2
            done
            psql -v ON_ERROR_STOP=1 -d umami <<'SQL'
            UPDATE "user" SET username = 'hmajid2301' WHERE user_id = '${adminUuid}';
            UPDATE "user" SET password = 'disabled' WHERE password <> 'disabled';
            SQL
          '';
        };

        umami-sso = {
          description = "Umami OIDC sidecar";
          after = [
            "network-online.target"
            "pocket-id.service"
            "umami.service"
          ];
          wants = [
            "network-online.target"
            "pocket-id.service"
          ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            HOST = "127.0.0.1";
            PORT = toString ssoPort;
            UMAMI_BASE_URL = "https://${host}";
            UMAMI_OIDC_ISSUER_URL = "https://${config.nixicle.domains.sso}";
            UMAMI_OIDC_CLIENT_ID = "umami";
            UMAMI_ADMIN_UUID = adminUuid;
          };
          serviceConfig = {
            ExecStart = lib.getExe pkgs.nixicle.umami-sso;
            EnvironmentFile = config.sops.templates."umami-sso.env".path;
            DynamicUser = true;
            Restart = "on-failure";
            RestartSec = 5;
            NoNewPrivileges = true;
            PrivateTmp = true;
            PrivateDevices = true;
            ProtectHome = true;
            ProtectSystem = "strict";
          };
        };
      };
    };
}
