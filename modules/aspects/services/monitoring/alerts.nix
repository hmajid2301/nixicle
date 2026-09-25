_:
let
  mkThresholdRule =
    {
      uid,
      title,
      expr,
      threshold,
      description,
      severity ? "warning",
      for ? "15m",
      noDataState ? "Alerting",
      execErrState ? "Error",
      cmp ? "lt",
      summary ? null,
      legendFormat ? "__auto",
      datasource ? {
        type = "prometheus";
        uid = "prometheus";
      },
    }:
    {
      inherit
        uid
        title
        for
        noDataState
        execErrState
        ;
      condition = "C";
      annotations = {
        summary = if summary == null then title else summary;
        inherit description;
      };
      labels = { inherit severity; };
      data = [
        {
          refId = "A";
          relativeTimeRange = {
            from = 600;
            to = 0;
          };
          datasourceUid = datasource.uid;
          model = {
            inherit datasource;
            editorMode = "code";
            inherit expr;
            instant = true;
            intervalMs = 1000;
            inherit legendFormat;
            maxDataPoints = 43200;
            range = false;
            refId = "A";
          };
        }
        {
          refId = "B";
          relativeTimeRange = {
            from = 0;
            to = 0;
          };
          datasourceUid = "__expr__";
          model = {
            conditions = [
              {
                evaluator.params = [ ];
                evaluator.type = "gt";
                operator.type = "and";
                query.params = [ "B" ];
                reducer.params = [ ];
                reducer.type = "last";
                type = "query";
              }
            ];
            datasource = {
              type = "__expr__";
              uid = "-100";
            };
            expression = "A";
            intervalMs = 1000;
            maxDataPoints = 43200;
            reducer = "last";
            refId = "B";
            settings.mode = "dropNN";
            type = "reduce";
          };
        }
        {
          refId = "C";
          relativeTimeRange = {
            from = 0;
            to = 0;
          };
          datasourceUid = "__expr__";
          model = {
            conditions = [
              {
                evaluator.params = [ threshold ];
                evaluator.type = cmp;
                operator.type = "and";
                query.params = [ "C" ];
              }
            ];
            datasource = {
              type = "__expr__";
              uid = "-100";
            };
            expression = "B";
            intervalMs = 1000;
            maxDataPoints = 43200;
            refId = "C";
            threshold = {
              conditions = [
                {
                  evaluator.params = [ threshold ];
                  evaluator.type = cmp;
                  operator.type = "and";
                  query.params = [ "C" ];
                }
              ];
            };
            type = "threshold";
          };
        }
      ];
    };
in
{
  den.aspects.monitoringAlerts = {
    nixos = { config, ... }: {
      services.grafana.provision.alerting = {
        rules.settings = {
          apiVersion = 1;
          groups = [
            {
              orgId = 1;
              name = "disk-space";
              folder = "System";
              interval = "1m";
              rules = [
                (mkThresholdRule {
                  uid = "vps-root-disk-low";
                  title = "VPS root filesystem below 15% free";
                  expr = ''100 * node_filesystem_avail_bytes{fstype="btrfs",mountpoint="/"} / node_filesystem_size_bytes{fstype="btrfs",mountpoint="/"}'';
                  threshold = 15;
                  description = ''
                    Free space on the vps root filesystem has been below 15% for 15m.
                    Attic and the Garage chunk store both live on this filesystem.
                  '';
                })
                (mkThresholdRule {
                  uid = "vps-root-disk-critical";
                  title = "VPS root filesystem below 7% free";
                  expr = ''100 * node_filesystem_avail_bytes{fstype="btrfs",mountpoint="/"} / node_filesystem_size_bytes{fstype="btrfs",mountpoint="/"}'';
                  threshold = 7;
                  severity = "critical";
                  for = "5m";
                  description = ''
                    Free space on the vps root filesystem has been below 7% for 5m.
                    Attic and the Garage chunk store both live on this filesystem.
                  '';
                })
              ];
            }
            {
              orgId = 1;
              name = "scrape-targets";
              folder = "System";
              interval = "1m";
              rules = [
                (mkThresholdRule {
                  uid = "scrape-target-down";
                  title = "Prometheus scrape target down";
                  expr = "up";
                  threshold = 1;
                  severity = "critical";
                  for = "5m";
                  description = ''
                    A Prometheus scrape target has been down for 5m+ (job {{ $labels.job }}, instance {{ $labels.instance }}).
                  '';
                })
              ];
            }
            {
              orgId = 1;
              name = "restic-backups";
              folder = "Backups";
              interval = "1m";
              rules = [
                (mkThresholdRule {
                  uid = "restic-backup-failed";
                  title = "Restic backup service failed";
                  expr = ''max_over_time(node_systemd_unit_state{name=~"restic-backups-.*",state="failed"}[10m])'';
                  cmp = "gt";
                  threshold = 0;
                  severity = "critical";
                  for = "5m";
                  summary = "Restic backup unit {{ $labels.name }} entered failed state";
                  legendFormat = "{{name}}";
                  description = ''
                    node_systemd_unit_state{name="{{ $labels.name }}",state="failed"} has been 1 for 5m+.
                  '';
                })
                (mkThresholdRule {
                  uid = "restic-backup-not-run";
                  title = "Restic backup not run within 24h";
                  expr = ''
                    (time() - max(node_systemd_timer_last_trigger_seconds{name=~"restic-backups-.*"})) > bool 90000
                  '';
                  cmp = "gt";
                  threshold = 0;
                  severity = "critical";
                  for = "0m";
                  summary = "No restic-backups timer fired in the last 25h";
                  legendFormat = "__auto";
                  description = ''
                    max(node_systemd_timer_last_trigger_seconds{name=~"restic-backups-.*"}) is older than 25h.
                      Backups may have silently stopped (timer disabled, dead, or never triggered).
                  '';
                })
                (mkThresholdRule {
                  uid = "restic-backup-timer-dead";
                  title = "Restic backup timer not active";
                  expr = ''
                    min(node_systemd_unit_state{name=~"restic-backups-.*\\.timer",state="active"})
                  '';
                  cmp = "lt";
                  threshold = 1;
                  severity = "critical";
                  for = "5m";
                  summary = "Restic backup timer {{ $labels.name }} is not active";
                  legendFormat = "__auto";
                  description = ''
                    min(node_systemd_unit_state{name=~"restic-backups-.*\\.timer",state="active"}) == 0.
                      A restic-backups timer is disabled, masked, or missing.
                  '';
                })
                (mkThresholdRule {
                  uid = "nas-restic-backup-failed";
                  title = "NAS restic backup failed";
                  datasource = {
                    type = "loki";
                    uid = "loki";
                  };
                  expr = ''
                    sum(count_over_time({host_name="nas",service_name=~"restic|restic-backups-homelab-.*"} |~ "Fatal" [10m])) or sum(count_over_time({host_name="nas",service_name="systemd"} |= "Failed with result" |= "restic-backups-homelab" [10m]))
                  '';
                  cmp = "gt";
                  threshold = 0;
                  severity = "critical";
                  for = "0m";
                  noDataState = "OK";
                  summary = "NAS restic-backups-homelab hit a Fatal error or failed unit";
                  legendFormat = "__auto";
                  description = ''
                    Fatal lines from the NAS restic stream, or a
                      "Failed with result" line for restic-backups-homelab,
                      in the last 10m (host_name="nas" in Loki).
                  '';
                })
                (mkThresholdRule {
                  uid = "nas-restic-backup-silent";
                  title = "NAS restic backup not run within 24h";
                  datasource = {
                    type = "loki";
                    uid = "loki";
                  };
                  expr = ''
                    (sum(count_over_time({host_name="nas",service_name="restic"} |= "snapshot" |= "saved" [25h])) or vector(0))
                  '';
                  cmp = "lt";
                  threshold = 1;
                  severity = "critical";
                  for = "0m";
                  summary = "No NAS restic snapshot saved in the last 25h";
                  legendFormat = "__auto";
                  description = ''
                    count_over_time({host_name="nas",service_name="restic"} |= "snapshot" |= "saved" [25h]) == 0.
                      NAS dead, timer disabled, restic failing, or the log
                      shipper broke — silence means no completed backup.
                  '';
                })
              ];
            }
          ];
        };

        # Contact point URL carries the app token; grafana expands
        # $GOTIFY_APP_TOKEN from its environment when provisioning, so the
        # token never lands in the nix store.
        contactPoints.settings = {
          apiVersion = 1;
          contactPoints = [
            {
              orgId = 1;
              name = "gotify";
              receivers = [
                {
                  uid = "gotify-webhook";
                  type = "webhook";
                  settings = {
                    url = "http://localhost:8051/message?token=$GOTIFY_APP_TOKEN";
                    httpMethod = "POST";
                  };
                }
              ];
            }
          ];
        };

        policies.settings = {
          apiVersion = 1;
          policies = [
            {
              orgId = 1;
              receiver = "gotify";
              group_by = [ "alertname" ];
              group_wait = "30s";
              group_interval = "5m";
              repeat_interval = "4h";
            }
          ];
        };
      };

      sops.secrets.gotify_grafana_app_token = { };

      sops.templates."gotify-grafana-env" = {
        content = ''
          GOTIFY_APP_TOKEN=${config.sops.placeholder.gotify_grafana_app_token}
        '';
        restartUnits = [ "grafana.service" ];
      };

      systemd.services.grafana.serviceConfig.EnvironmentFile = [
        config.sops.templates."gotify-grafana-env".path
      ];
    };
  };
}
