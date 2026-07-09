{
  inputs,
  ...
}:
{
  flake-file.inputs.authentik-nix.url = "github:nix-community/authentik-nix";

  den.aspects.authentik = {
    includes = [ ];
    persist.directories = [
      {
        directory = "/var/lib/private/authentik";
        user = "authentik";
        group = "authentik";
        mode = "0750";
        defaultPerms.mode = "0700";
      }
    ];
    nixos =
      { config, lib, secrets, ... }:
      let
        secretPaths = lib.mergeAttrsList secrets;
      in
      {
        imports = [ inputs.authentik-nix.nixosModules.default ];
        sops.secrets.authenik_env = { };
        services = {
          authentik = {
            enable = true;
            environmentFile = secretPaths.authenik_env;
            settings = {
              email = {
                host = "smtp.mailgun.org";
                port = 587;
                username = "postmaster@sandbox92beea2c073042199273861834e24d1f.mailgun.org";
                use_tls = true;
                use_ssl = false;
                from = "homelab@haseebmajid.dev";
              };
              disable_startup_analytics = true;
              avatars = "initials";
            };
          };

          traefik.dynamicConfigOptions.http = lib.mkMerge [
            {
              middlewares.authentik.forwardAuth = {
                tls.insecureSkipVerify = true;
                address = "https://localhost:9443/outpost.goauthentik.io/auth/traefik";
                trustForwardHeader = true;
                authResponseHeaders = [
                  "X-authentik-username"
                  "X-authentik-groups"
                  "X-authentik-email"
                  "X-authentik-name"
                  "X-authentik-uid"
                  "X-authentik-jwt"
                  "X-authentik-meta-jwks"
                  "X-authentik-meta-outpost"
                  "X-authentik-meta-provider"
                  "X-authentik-meta-app"
                  "X-authentik-meta-version"
                ];
              };
            }
            (lib.nixicle.mkTraefikService {
              name = "auth";
              port = 9000;
              subdomain = "authentik";
              domain = "haseebmajid.dev";
              extraRouterConfig.rule = "Host(`authentik.haseebmajid.dev`) || HostRegexp(`{subdomain:[a-z0-9]+}.homelab.haseebmajid.com`) && PathPrefix(`/outpost.goauthentik.io/`)";
            })
          ];
        };

      };
  };
}
