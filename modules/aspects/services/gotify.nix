_: {
  den.aspects.gotify = {

    persist.directories = [
      {
        directory = "/var/lib/gotify-server";
        user = "gotify";
        group = "gotify";
        mode = "0755";
      }
    ];

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        port = 8051;
        domain = config.nixicle.domains.root;
      in
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

        systemd.services.gotify-server = {
          after = [
            "traefik.service"
            "pocket-id.service"
          ];
          wants = [
            "traefik.service"
            "pocket-id.service"
          ];
          preStart = ''
            ${lib.getExe pkgs.curl} --fail --silent --show-error \
              --retry 60 --retry-all-errors --retry-delay 1 --retry-max-time 60 --max-time 5 \
              ${lib.escapeShellArg "${config.services.gotify.environment.GOTIFY_OIDC_ISSUER}/.well-known/openid-configuration"} \
              --output /dev/null
          '';
          serviceConfig = {
            DynamicUser = lib.mkForce false;
            User = "gotify";
            Group = "gotify";
            EnvironmentFile = [ config.sops.secrets.gotify_env.path ];
          };
        };

        sops.secrets.gotify_env.owner = "gotify";
      };
  };
}
