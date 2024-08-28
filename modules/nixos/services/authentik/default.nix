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

  config = mkIf cfg.enable {
    sops.secrets.authenik_env = {
      sopsFile = ../secrets.yaml;
    };

    services = {
      authentik = {
        enable = true;
        environmentFile = config.sops.secrets.authenik_env.path;
        settings = {
          # TODO: fill this settings
          email = {
            host = "smtp.mailgun.org";
            port = 587;
            username = "postmaster@sandbox92beea2c073042199273861834e24d1f.mailgun.org";
            use_tls = true;
            use_ssl = false;
            from = "hello@haseebmajid.dev";
          };
          disable_startup_analytics = true;
          avatars = "initials";
        };
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            middlewares = {
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

            services = {
              auth.loadBalancer.servers = [
                {
                  url = "http://localhost:9000";
                }
              ];
            };

            routers = {
              auth = {
                entryPoints = ["websecure"];
                rule = "Host(`authentik.haseebmajid.dev`) || HostRegexp(`{subdomain:[a-z0-9]+}.haseebmajid.com`) && PathPrefix(`/outpost.goauthentik.io/`)";
                service = "auth";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
