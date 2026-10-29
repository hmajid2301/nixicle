_: {
  den.aspects.monitoringPrometheus = {
    persist.directories = [
      {
        directory = "/var/lib/prometheus2";
        mode = "0755";
      }
    ];

    nixos =
      { config, pkgs, ... }:
      {
        services.prometheus = {
          port = 3020;
          listenAddress = "127.0.0.1";
          enable = true;
          checkConfig = "syntax-only";
          extraFlags = [
            "--web.enable-admin-api"
            "--storage.tsdb.retention.time=180d"
          ];

          exporters = {
            blackbox = {
              enable = true;
              listenAddress = "127.0.0.1";
              configFile = (pkgs.formats.yaml { }).generate "blackbox.yml" {
                modules = {
                  grafana-health = {
                    prober = "http";
                    timeout = "10s";
                    http = {
                      valid_status_codes = [ 200 ];
                      follow_redirects = false;
                      fail_if_not_ssl = true;
                      fail_if_body_not_matches_regexp = [ ''"database"\s*:\s*"ok"'' ];
                    };
                  };
                  jellyfin-health = {
                    prober = "http";
                    timeout = "10s";
                    http = {
                      valid_status_codes = [ 200 ];
                      follow_redirects = false;
                      fail_if_not_ssl = true;
                      fail_if_body_not_matches_regexp = [ "Healthy" ];
                    };
                  };
                  oidc-discovery = {
                    prober = "http";
                    timeout = "10s";
                    http = {
                      valid_status_codes = [ 200 ];
                      follow_redirects = false;
                      fail_if_not_ssl = true;
                      fail_if_body_not_matches_regexp = [ ''"issuer"\s*:'' ];
                    };
                  };
                  tcp-connect = {
                    prober = "tcp";
                    timeout = "5s";
                  };
                };
              };
            };
            redis.enable = true;
            postgres = {
              enable = true;
              runAsLocalSuperUser = true;
              extraFlags = [ "--collector.stat_checkpointer" ];
            };
            node = {
              port = 3021;
              enabledCollectors = [ "systemd" ];
              enable = true;
            };
          };

          scrapeConfigs = [
            {
              job_name = "blackbox";
              metrics_path = "/probe";
              scrape_interval = "60s";
              scrape_timeout = "15s";
              static_configs = [
                {
                  targets = [ "https://grafana.${config.nixicle.domains.homelab}/api/health" ];
                  labels = {
                    service = "grafana";
                    module = "grafana-health";
                  };
                }
                {
                  targets = [ "https://jellyfin.haseebmajid.dev/health" ];
                  labels = {
                    service = "jellyfin";
                    module = "jellyfin-health";
                  };
                }
                {
                  targets = [ "https://${config.nixicle.domains.sso}/.well-known/openid-configuration" ];
                  labels = {
                    service = "sso";
                    module = "oidc-discovery";
                  };
                }
                {
                  targets = [ "nas:2049" ];
                  labels = {
                    service = "nas-nfs";
                    module = "tcp-connect";
                  };
                }
              ];
              relabel_configs = [
                {
                  source_labels = [ "__address__" ];
                  target_label = "__param_target";
                }
                {
                  source_labels = [ "module" ];
                  target_label = "__param_module";
                }
                {
                  source_labels = [ "__param_target" ];
                  target_label = "instance";
                }
                {
                  target_label = "__address__";
                  replacement = "127.0.0.1:${toString config.services.prometheus.exporters.blackbox.port}";
                }
              ];
            }
            {
              job_name = "smartctl";
              scrape_interval = "60s";
              static_configs = [
                {
                  targets = [ "nas:9633" ];
                  labels.host = "nas";
                }
              ];
            }
            {
              job_name = "grafana";
              static_configs = [ { targets = [ "127.0.0.1:3010" ]; } ];
            }
            {
              job_name = "otel-internal";
              static_configs = [ { targets = [ "127.0.0.1:8888" ]; } ];
            }
            {
              job_name = "redis";
              metrics_path = "/metrics";
              static_configs = [
                { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.redis.port}" ]; }
              ];
            }
            {
              job_name = "postgres";
              static_configs = [
                { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.postgres.port}" ]; }
              ];
            }
            {
              job_name = "otel-collector";
              static_configs = [ { targets = [ "127.0.0.1:8889" ]; } ];
            }
            {
              job_name = "nodes";
              static_configs = [
                {
                  targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
                  labels.host = "vps";
                }
                {
                  targets = [ "nas:3021" ];
                  labels.host = "nas";
                }
              ];
            }
            {
              job_name = "zfs";
              static_configs = [
                {
                  targets = [ "nas:9134" ];
                  labels.host = "nas";
                }
              ];
            }
            {
              job_name = "crowdsec";
              static_configs = [ { targets = [ "127.0.0.1:6060" ]; } ];
            }
            {
              job_name = "traefik";
              static_configs = [ { targets = [ "127.0.0.1:8080" ]; } ];
            }
            {
              job_name = "loki";
              static_configs = [ { targets = [ "127.0.0.1:3030" ]; } ];
            }
            {
              job_name = "tempo";
              static_configs = [ { targets = [ "127.0.0.1:4400" ]; } ];
            }
            {
              job_name = "garage";
              static_configs = [ { targets = [ "127.0.0.1:3903" ]; } ];
            }
            {
              job_name = "prometheus";
              static_configs = [ { targets = [ "127.0.0.1:${toString config.services.prometheus.port}" ]; } ];
            }
          ];
        };
      };
  };
}
