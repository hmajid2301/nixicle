{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.traefik;
in {
  options.services.nixicle.traefik = {
    enable = mkEnableOption "Enable traefik";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [80 443];

    systemd.services.traefik = {
      environment = {
        CF_API_EMAIL = "hello@haseebmajid.dev";
      };
      serviceConfig = {
        EnvironmentFile = [config.sops.secrets.cloudflare_api_key.path];
      };
    };

    sops.secrets.cloudflare_api_key = {
      sopsFile = ../secrets.yaml;
    };

    services = {
      tailscale.permitCertUid = "traefik";

      traefik = {
        enable = true;

        # TODO: dynamically enable if enabled using host and port rather than hard coding it
        dynamicConfigOptions = {
          http = {
            services = {
              # TODO: how to do this over devices?
              homeassistant.loadBalancer.servers = [
                {
                  url = "http://192.168.1.44:8123";
                }
              ];
            };

            routers = {
              homeassistant = {
                entryPoints = ["websecure"];
                rule = "Host(`home-assistant.bare.homelab.haseebmajid.dev`)";
                service = "homeassistant";
                tls.certResolver = "letsencrypt";
              };

              traefik-dashboard = {
                entryPoints = ["websecure"];
                rule = "Host(`traefik.bare.homelab.haseebmajid.dev`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))";
                service = "api@internal";
                tls.certResolver = "letsencrypt";
                # middlewares = ["authentik"];
              };
            };
          };
        };
        staticConfigOptions = {
          log = {
            level = "INFO";
            filePath = "/var/log/traefik.log";
            # format = "json";  # Uses text format (common) by default
            noColor = false;
            maxSize = 100;
            compress = true;
          };

          metrics = {
            prometheus = {};
          };

          # tracing = {};

          accessLog = {
            addInternals = true;
            filePath = "/var/log/traefik-access.log";
            bufferingSize = 100; # Number of log lines
            fields = {
              names = {
                StartUTC = "drop"; # Write logs in Container Local Time instead of UTC
              };
            };
            filters = {
              statusCodes = [
                "204-299"
                "400-499"
                "500-599"
              ];
            };
          };
          api = {
            dashboard = true;
            insecure = true;
          };
          certificatesResolvers = {
            tailscale.tailscale = {};
            letsencrypt = {
              acme = {
                email = "hello@haseebmajid.dev";
                storage = "/var/lib/traefik/cert.json";
                dnsChallenge = {
                  provider = "cloudflare";
                };
              };
            };
          };

          entryPoints.web = {
            address = ":80";
            http.redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
              permanent = true;
            };
          };
          entryPoints.websecure = {
            address = ":443";
            http.tls = {
              certResolver = "letsencrypt";
              domains = [
                {
                  main = "bare.homelab.haseebmajid.dev";
                  sans = ["*.bare.homelab.haseebmajid.dev"];
                }
              ];
            };
          };
        };
      };
    };
  };
}
