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
            TINYAUTH_APPURL = "https://auth.${domain}";
            TINYAUTH_SERVER_PORT = toString authPort;
            TINYAUTH_DATABASE_PATH = "/var/lib/tinyauth/tinyauth.db";
            TINYAUTH_OAUTH_PROVIDERS_pocketid_AUTHURL = "https://id.${domain}/authorize";
            TINYAUTH_OAUTH_PROVIDERS_pocketid_TOKENURL = "https://id.${domain}/api/oidc/token";
            TINYAUTH_OAUTH_PROVIDERS_pocketid_USERINFOURL = "https://id.${domain}/api/oidc/userinfo";
            TINYAUTH_OAUTH_PROVIDERS_pocketid_REDIRECTURL = "https://auth.${domain}/api/oauth/callback/pocketid";
            TINYAUTH_OAUTH_PROVIDERS_pocketid_SCOPES = "openid profile email groups";
            TINYAUTH_OAUTH_PROVIDERS_pocketid_NAME = "Pocket ID";
            TINYAUTH_OAUTH_AUTOREDIRECT = "pocketid";
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
