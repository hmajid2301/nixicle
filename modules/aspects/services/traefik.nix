_: {
  den.aspects.traefik = {
    persist.directories = [ "/var/lib/traefik" ];
    nixos =
      { config, ... }:
      {
        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        sops.secrets.gandi_personal_access_token = {
          owner = "traefik";
        };

        systemd.services.traefik = {
          serviceConfig.EnvironmentFile = config.sops.secrets.gandi_personal_access_token.path;
        };

        services.tailscale.permitCertUid = "traefik";

        services.traefik = {
          enable = true;
          staticConfigOptions = {
            metrics.prometheus = { };
            tracing = { };
            accessLog = { };
            api = {
              dashboard = true;
              insecure = true;
            };
            certificatesResolvers = {
              tailscale.tailscale = { };
              letsencrypt.acme = {
                email = config.nixicle.identity.adminEmail;
                storage = "/var/lib/traefik/cert.json";
                dnsChallenge = {
                  provider = "gandiv5";
                  propagation = {
                    disableANSChecks = true;
                    delayBeforeChecks = 30;
                  };
                };
              };
            };
            entryPoints = {
              web = {
                address = "0.0.0.0:80";
                http.redirections.entryPoint = {
                  to = "websecure";
                  scheme = "https";
                  permanent = true;
                };
              };
              websecure = {
                address = "0.0.0.0:443";
                http.tls = {
                  certResolver = "letsencrypt";
                  domains = [
                    {
                      main = config.nixicle.domains.homelab;
                      sans = [ "*.${config.nixicle.domains.homelab}" ];
                    }
                    {
                      main = config.nixicle.domains.root;
                      sans = [ "*.${config.nixicle.domains.root}" ];
                    }
                    {
                      main = "banterbus.games";
                      sans = [ "*.dev.banterbus.games" ];
                    }
                  ];
                };
                transport.respondingTimeouts = {
                  readTimeout = "0";
                  writeTimeout = "30m";
                  idleTimeout = "30m";
                };
              };
            };
          };

          dynamicConfigOptions.http = {
            routers.traefik = {
              entryPoints = [ "websecure" ];
              rule = "Host(`traefik.homelab.haseebmajid.dev`)";
              middlewares = [ "tinyauth" ];
              service = "api@internal";
              tls.certResolver = "letsencrypt";
            };
          };
        };

      };
  };
}
