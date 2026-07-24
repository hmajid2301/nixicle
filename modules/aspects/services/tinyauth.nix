{ ... }:
let
  port = 3939;
  authPort = 3000;
  domain = "haseebmajid.dev";
in
{
  den.aspects.tinyauth = {
    includes = [ ];
    persist.directories = [ "/var/lib/tinyauth" ];

    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        sops.secrets.tinyauth_env = { };

        users.users.tinyauth = {
          isSystemUser = true;
          group = "tinyauth";
          home = "/var/lib/tinyauth";
          createHome = true;
        };
        users.groups.tinyauth = { };

        systemd.services.tinyauth = {
          description = "TinyAuth forward-auth (pocket-id OIDC)";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          environment = {
            APP_URL = "https://auth.${domain}";
            PORT = toString authPort;
            PROVIDERS_POCKETID_AUTH_URL = "https://id.${domain}/authorize";
            PROVIDERS_POCKETID_TOKEN_URL = "https://id.${domain}/api/oidc/token";
            PROVIDERS_POCKETID_USER_INFO_URL = "https://id.${domain}/api/oidc/userinfo";
            PROVIDERS_POCKETID_REDIRECT_URL = "https://auth.${domain}/api/oauth/callback/pocketid";
            PROVIDERS_POCKETID_SCOPES = "openid profile email groups";
            PROVIDERS_POCKETID_NAME = "Pocket ID";
            OAUTH_AUTO_REDIRECT = "pocketid";
          };
          serviceConfig = {
            ExecStart = lib.getExe pkgs.tinyauth;
            EnvironmentFile = config.sops.secrets.tinyauth_env.path;
            User = "tinyauth";
            Group = "tinyauth";
            StateDirectory = "tinyauth";
            Restart = "on-failure";
          };
        };

        services.traefik.dynamicConfigOptions.http = {
          middlewares.tinyauth.forwardAuth = {
            address = "http://127.0.0.1:${toString authPort}/api/auth/traefik";
            authResponseHeaders = [
              "Remote-User"
              "Remote-Name"
              "Remote-Email"
              "Remote-Groups"
            ];
          };
          routers.tinyauth = {
            entryPoints = [ "websecure" ];
            rule = "Host(`auth.${domain}`)";
            service = "tinyauth";
            tls.certResolver = "letsencrypt";
          };
          services.tinyauth.loadBalancer.servers = [
            { url = "http://127.0.0.1:${toString authPort}"; }
          ];
        };
      };
  };
}
