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

        staticConfigOptions = {
          log = {
            level = "INFO";
            filePath = "/var/log/traefik.log";
            format = "json";
            noColor = false;
            maxSize = 100;
            compress = true;
          };

          metrics = {
            prometheus = {};
          };

          tracing = {};

          accessLog = {
            addInternals = true;
            filePath = "/var/log/traefik-access.log";
            bufferingSize = 100;
            fields = {
              names = {
                StartUTC = "drop";
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

          entryPoints = {
            redis = {
              address = "0.0.0.0:6381";
            };

            postgres = {
              address = "0.0.0.0:5433";
            };

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
                    sans = ["*.homelab.haseebmajid.dev"];
                  }
                  {
                    main = "haseebmajid.dev";
                    sans = ["*.haseebmajid.dev"];
                  }
                ];
              };
            };
          };
        };
      };
    };
  };
}
