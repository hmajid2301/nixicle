{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.monitoring;
in {
  options.services.nixicle.monitoring = {
    enable = mkEnableOption "Enable The monitoring stack(loki, prometheus, grafana)";
  };

  config = mkIf cfg.enable {
    services = {
      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              prometheus.loadBalancer.servers = [
                {
                  url = "http://localhost:3020";
                }
              ];
              loki.loadBalancer.servers = [
                {
                  url = "http://localhost:3030";
                }
              ];
              grafana.loadBalancer.servers = [
                {
                  url = "http://localhost:3010";
                }
              ];
              promtail.loadBalancer.servers = [
                {
                  url = "http://localhost:3031";
                }
              ];
            };

            routers = {
              prometheus = {
                entryPoints = ["websecure"];
                rule = "Host(`prometheus.bare.homelab.haseebmajid.dev`)";
                service = "prometheus";
                tls.certResolver = "letsencrypt";
              };
              loki = {
                entryPoints = ["websecure"];
                rule = "Host(`loki.bare.homelab.haseebmajid.dev`)";
                service = "loki";
                tls.certResolver = "letsencrypt";
              };
              grafana = {
                entryPoints = ["websecure"];
                rule = "Host(`grafana.bare.homelab.haseebmajid.dev`)";
                service = "grafana";
                tls.certResolver = "letsencrypt";
              };
              promtail = {
                entryPoints = ["websecure"];
                rule = "Host(`promtail.bare.homelab.haseebmajid.dev`)";
                service = "promtail";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };

      prometheus = {
        port = 3020;
        enable = true;

        exporters = {
          node = {
            port = 3021;
            enabledCollectors = ["systemd"];
            enable = true;
          };
        };

        scrapeConfigs = [
          {
            job_name = "nodes";
            static_configs = [
              {
                targets = [
                  "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
                ];
              }
            ];
          }
        ];
      };

      # loki = {
      #   enable = true;
      #   configuration = {
      #     server.http_listen_port = 3030;
      #   };
      # };

      # promtail = {
      #   enable = true;
      #   configuration = {
      #     server = {
      #       http_listen_port = 3031;
      #       grpc_listen_port = 0;
      #     };
      #     positions = {
      #       filename = "/tmp/positions.yaml";
      #     };
      #     clients = [
      #       # {
      #       #   url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
      #       # }
      #     ];
      #     scrape_configs = [
      #       {
      #         job_name = "journal";
      #         journal = {
      #           max_age = "12h";
      #           labels = {
      #             job = "systemd-journal";
      #             host = "pihole";
      #           };
      #         };
      #         relabel_configs = [
      #           {
      #             source_labels = ["__journal__systemd_unit"];
      #             target_label = "unit";
      #           }
      #         ];
      #       }
      #     ];
      #   };
      # };

      grafana = {
        port = 3010;
        # WARNING: this should match nginx setup!
        # prevents "Request origin is not authorized"
        rootUrl = "http://192.168.1.10:8010"; # helps with nginx / ws / live

        protocol = "http";
        addr = "127.0.0.1";
        analytics.reporting.enable = false;
        enable = true;

        provision = {
          enable = true;
          datasources = {
            settings = {
              datasources = [
                {
                  name = "Prometheus";
                  type = "prometheus";
                  access = "proxy";
                  url = "http://127.0.0.1:${toString config.services.prometheus.port}";
                }
                # {
                #   name = "Loki";
                #   type = "loki";
                #   access = "proxy";
                #   url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
                # }
              ];
            };
          };
        };
      };
    };
  };
}
