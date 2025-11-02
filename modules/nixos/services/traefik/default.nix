{
  config,
  lib,
  pkgs,
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
    ];

    users.groups.k3s = lib.mkIf config.services.k3s.enable { };

    users.users.traefik = lib.mkIf config.services.k3s.enable {
      extraGroups = [ "k3s" ];
    };

    systemd.services.traefik = {
      environment = {
        CF_API_EMAIL = "hello@haseebmajid.dev";
      };
      serviceConfig = {
        EnvironmentFile = [ config.sops.secrets.cloudflare_api_key.path ];
        SupplementaryGroups = lib.mkIf config.services.k3s.enable [ "k3s" ];
      };
      after = lib.mkIf config.services.k3s.enable [ "k3s.service" ];
      wants = lib.mkIf config.services.k3s.enable [ "k3s.service" ];
      requires = lib.mkIf config.services.k3s.enable [ "k3s.service" ];
    };

    sops.secrets = {
      cloudflare_api_key = {
        sopsFile = ../secrets.yaml;
      };
      k8s_traefik_token = lib.mkIf config.services.k3s.enable {
        sopsFile = ../secrets.yaml;
        owner = "traefik";
        group = "traefik";
      };
      k8s_traefik_ca = lib.mkIf config.services.k3s.enable {
        sopsFile = ../secrets.yaml;
        owner = "traefik";
        group = "traefik";
      };
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

          providers = lib.mkIf config.services.k3s.enable {
            kubernetesIngress = {
              endpoint = "https://vps:6443";
              token = config.sops.secrets.k8s_traefik_token.path;
              certAuthFilePath = config.sops.secrets.k8s_traefik_ca.path;
              ingressClass = "traefik";
            };
            kubernetesCRD = {
              endpoint = "https://vps:6443";
              token = config.sops.secrets.k8s_traefik_token.path;
              certAuthFilePath = config.sops.secrets.k8s_traefik_ca.path;
            };
          };

          entryPoints = {
            redis = {
              address = "0.0.0.0:6381";
            };

            valkey = {
              address = "0.0.0.0:6382";
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
            };
          };
        };
      };
    };
  };
}
