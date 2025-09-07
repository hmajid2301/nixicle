{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.traefik;
in
{
  options.services.nixicle.traefik = {
    enable = mkEnableOption "Enable traefik";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      80
      443
      6381
      5433
    ];

    systemd.services.traefik = {
      environment = {
        CF_API_EMAIL = "hello@haseebmajid.dev";
      };
      serviceConfig = {
        EnvironmentFile = [ config.sops.secrets.cloudflare_api_key.path ];
      };
    };

    sops.secrets.cloudflare_api_key = {
      sopsFile = ../secrets.yaml;
    };

    sops.secrets.k3s_traefik_token = {
      sopsFile = ../secrets.yaml;
    };

    services = {
      tailscale.permitCertUid = "traefik";

      traefik = {
        enable = true;

        staticConfigOptions = {
          metrics = {
            prometheus = { };
          };

          tracing = { };

          api = {
            dashboard = true;
          };

          providers = {
            docker = {
              endpoint = "unix:///var/run/docker.sock";
              exposedByDefault = false;
              swarmMode = true;
              network = "traefik-network";
              watch = true;
            };
            kubernetes = {
              endpoint = "https://vps:6443";
              token = "/run/secrets/k3s_traefik_token";
              namespaces = ["default" "kube-system"];
            };
            kubernetesIngress = {
              endpoint = "https://vps:6443";
              token = "/run/secrets/k3s_traefik_token";
              namespaces = ["default" "kube-system"];
            };
            file = {
              directory = "/etc/traefik/dynamic";
              watch = true;
            };
          };

          certificatesResolvers = {
            tailscale.tailscale = { };
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
                    main = "banterbus.games";
                    sans = [ "*.banterbus.games" ];
                  }
                  {
                    main = "homelab.haseebmajid.dev";
                    sans = [ "*.homelab.haseebmajid.dev" ];
                  }
                  {
                    main = "haseebmajid.dev";
                    sans = [ "*.haseebmajid.dev" ];
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
