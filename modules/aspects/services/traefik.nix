{ ... }:
{
  den.aspects.traefik = {
    includes = [ ];
    persist.directories = [ "/var/lib/traefik" ];
    nixos =
      { config, ... }:
      {
        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        sops.secrets.cloudflare_api_key = {
                    owner = "traefik";
        };

        systemd.services.traefik = {
          serviceConfig.EnvironmentFile = config.sops.secrets.cloudflare_api_key.path;
          environment = {
            CF_API_EMAIL = "hello@haseebmajid.dev";
          };
        };

        services.tailscale.permitCertUid = "traefik";

        services.traefik = {
          enable = true;
          staticConfigOptions = {
            metrics.prometheus = { };
            tracing = { };
            api.dashboard = true;
            certificatesResolvers = {
              tailscale.tailscale = { };
              letsencrypt.acme = {
                email = "hello@haseebmajid.dev";
                storage = "/var/lib/traefik/cert.json";
                dnsChallenge = {
                  provider = "cloudflare";
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
                      main = "homelab.haseebmajid.dev";
                      sans = [ "*.homelab.haseebmajid.dev" ];
                    }
                    {
                      main = "haseebmajid.dev";
                      sans = [ "*.haseebmajid.dev" ];
                    }
                    {
                      main = "banterbus.games";
                      sans = [ "*.dev.banterbus.games" ];
                    }
                  ];
                };
                transport.respondingTimeouts = {
                  readTimeout = "30m";
                  writeTimeout = "30m";
                  idleTimeout = "30m";
                };
              };
            };
          };
        };

      };
  };
}
