{ ... }:
let
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
        ...
      }:
      {
        sops.secrets.tinyauth_env = {
          owner = "tinyauth";
          group = "tinyauth";
        };

        services.tinyauth = {
          enable = true;
          environmentFile = config.sops.secrets.tinyauth_env.path;
          settings = {
            SERVER_ADDRESS = "127.0.0.1";
            SERVER_PORT = authPort;
            APPURL = "https://auth.${domain}";
            ANALYTICS_ENABLED = false;
            OAUTH_PROVIDERS_pocketid_AUTHURL = "https://id.${domain}/authorize";
            OAUTH_PROVIDERS_pocketid_TOKENURL = "https://id.${domain}/api/oidc/token";
            OAUTH_PROVIDERS_pocketid_USERINFOURL = "https://id.${domain}/api/oidc/userinfo";
            OAUTH_PROVIDERS_pocketid_REDIRECTURL = "https://auth.${domain}/api/oauth/callback/pocketid";
            OAUTH_PROVIDERS_pocketid_SCOPES = "openid profile email groups";
            OAUTH_PROVIDERS_pocketid_NAME = "Pocket ID";
            OAUTH_AUTOREDIRECT = "pocketid";
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
