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
              homeassistant.loadBalancer.servers = [
                {
                  url = "http://s100:8123";
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
            };
          };
        };
        staticConfigOptions = {
          log = {
            level = "INFO"; # Options: DEBUG, PANIC, FATAL, ERROR (Default), WARN, and INFO
            filePath = "/var/log/traefik.log"; # Default is to STDOUT
            # format = "json";  # Uses text format (common) by default
            noColor = false; # Recommended to be true when using common
            maxSize = 100; # In megabytes
            compress = true;
          };
          accessLog = {
            addInternals = true; # things like ping@internal
            filePath = "/var/log/traefik-access.log"; # In the Common Log Format (CLF) by default
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
            insecure = true;
            dashboard = true;
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
            address = "0.0.0.0:80";
            http.redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
              permanent = true;
            };
          };
          entryPoints.websecure = {
            address = "0.0.0.0:443";
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
