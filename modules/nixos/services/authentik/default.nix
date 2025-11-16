{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.authentik;
in {
  options.services.nixicle.authentik = {
    enable = mkEnableOption "Enable the authentik auth service";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      sops.secrets.authenik_env = {
        sopsFile = ../secrets.yaml;
      };

      services = {
        authentik = {
          enable = true;
          environmentFile = config.sops.secrets.authenik_env.path;
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

        cloudflared = {
          tunnels = {
            "ec0b6af0-a823-4616-a08b-b871fd2c7f58" = {
              ingress = {
                "authentik.haseebmajid.dev" = "http://localhost:9000";
              };
            };
          };
        };

        traefik = {
          dynamicConfigOptions = {
            http.middlewares = {
              authentik = {
                forwardAuth = {
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
              };
            };
          };
        };
      };
    }

    # Traefik reverse proxy configuration
    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "auth";
        port = 9000;
        subdomain = "authentik";
        domain = "haseebmajid.dev";
        extraRouterConfig = {
          rule = "Host(`authentik.haseebmajid.dev`) || HostRegexp(`{subdomain:[a-z0-9]+}.homelab.haseebmajid.com`) && PathPrefix(`/outpost.goauthentik.io/`)";
        };
      };
    }
  ]);
}
