_:
let
  port = 8051;
  domain = "haseebmajid.dev";
in
{
  den.aspects.gotify = {
    includes = [ ];

    persist.directories = [
      {
        directory = "/var/lib/gotify-server";
        user = "gotify";
        group = "gotify";
        mode = "0755";
      }
    ];

    nixos =
      { config, lib, ... }:
      {
        users = {
          users.gotify = {
            isSystemUser = true;
            group = "gotify";
            home = "/var/lib/gotify-server";
          };
          groups.gotify = { };
        };

        services = {
          gotify = {
            enable = true;
            environment = {
              GOTIFY_SERVER_PORT = port;
              GOTIFY_OIDC_ENABLED = "true";
              GOTIFY_OIDC_ISSUER = "https://id.${domain}";
              GOTIFY_OIDC_REDIRECTURL = "https://gotify.${domain}/auth/oidc/callback";
              GOTIFY_OIDC_SCOPES = "openid,profile,email,groups";
              GOTIFY_OIDC_GROUPS_CLAIM = "groups";
              GOTIFY_OIDC_GROUPS_ADMIN = "Gotify Admins";
              GOTIFY_OIDC_IDP_NAME = "Pocket ID";
              GOTIFY_SERVER_SECURECOOKIE = "true";
              GOTIFY_SERVER_TRUSTEDPROXIES = "127.0.0.1/32,::1";
            };
          };

          traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
            name = "gotify";
            inherit port domain;
          };
        };

        systemd.services.gotify-server.serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = "gotify";
          Group = "gotify";
          EnvironmentFile = [ config.sops.secrets.gotify_env.path ];
        };

        sops.secrets.gotify_env.owner = "gotify";
      };
  };
}
