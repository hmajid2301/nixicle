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
          deleteRules = [
            {
              orgId = 1;
              uid = "nas-restic-backup-failed";
            }
            {
              orgId = 1;
              uid = "nas-restic-backup-silent";
            }
          ];
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
                  expr = ''100 * node_filesystem_avail_bytes{host="vps",fstype="btrfs",mountpoint="/"} / node_filesystem_size_bytes{host="vps",fstype="btrfs",mountpoint="/"}'';
                  threshold = 15;
                  description = ''
                    Free space on the vps root filesystem has been below 15% for 15m.
                    Attic and the Garage chunk store both live on this filesystem.
                  '';
                })
                (mkThresholdRule {
                  uid = "vps-root-disk-critical";
                  title = "VPS root filesystem below 7% free";
                  expr = ''100 * node_filesystem_avail_bytes{host="vps",fstype="btrfs",mountpoint="/"} / node_filesystem_size_bytes{host="vps",fstype="btrfs",mountpoint="/"}'';
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
                  title = "Restic backup has no successful run within 30h";
                  expr = ''
                    time() - (
                      (restic_backup_last_success_timestamp_seconds and on(host, backup) restic_backup_expected)
                      or on(host, backup) (0 * restic_backup_expected)
                    )
                  '';
                  cmp = "gt";
                  threshold = 108000;
                  severity = "critical";
                  for = "5m";
                  summary = "Backup {{ $labels.backup }} on {{ $labels.host }} has no recent success";
                  legendFormat = "{{host}} / {{backup}}";
                  description = ''
                    No successful backup job completion for 30h, or this expected job has never reported success.
                    A skipped run (including a locked NAS dataset) does not update the success timestamp.
                  '';
                })
                (mkThresholdRule {
                  uid = "restic-backup-timer-dead";
                  title = "Restic backup timer not active";
                  expr = ''
                    label_replace(restic_backup_expected, "name", "restic-backups-$1.timer", "backup", "(.+)")
                    unless on(host, name) (node_systemd_unit_state{name=~"restic-backups-.*\\.timer",state="active"} == 1)
                  '';
                  cmp = "gt";
                  threshold = 0;
                  noDataState = "OK";
                  severity = "critical";
                  for = "5m";
                  summary = "Restic backup timer {{ $labels.name }} is not active on {{ $labels.host }}";
                  legendFormat = "__auto";
                  description = ''
                    An expected backup timer is inactive or missing from systemd metrics.
                  '';
                })
                (mkThresholdRule {
                  uid = "restic-inventory-missing";
                  title = "Backup metrics inventory missing";
                  expr = ''up{job="nodes"} unless on(host) restic_backup_expected'';
                  cmp = "gt";
                  threshold = 0;
                  noDataState = "OK";
                  severity = "critical";
                  for = "5m";
                  description = "A reachable node is missing its expected-backup inventory. Check the node textfile collector.";
                })
              ];
            }
            {
              orgId = 1;
              name = "homelab-health";
              folder = "System";
              interval = "1m";
              rules = map mkThresholdRule [
                {
                  uid = "homelab-filesystem-low";
                  title = "Homelab filesystem below 10% free";
                  expr = ''100 * node_filesystem_avail_bytes{job="nodes",fstype!~"tmpfs|devtmpfs|overlay|squashfs",mountpoint!~"/boot.*"} / node_filesystem_size_bytes'';
                  threshold = 10;
                  description = "Filesystem {{ $labels.mountpoint }} on {{ $labels.host }} is below 10% available space.";
                }
                {
                  uid = "nas-pool-unhealthy";
                  title = "NAS ZFS pool unhealthy";
                  expr = ''zfs_pool_health{host="nas",pool="main"}'';
                  cmp = "gt";
                  threshold = 0;
                  severity = "critical";
                  for = "5m";
                  description = "ZFS pool main is not ONLINE. Check zpool status on the NAS.";
                }
                {
                  uid = "nas-pool-capacity";
                  title = "NAS ZFS pool above 80% allocated";
                  expr = ''100 * zfs_pool_allocated_bytes{host="nas"} / zfs_pool_size_bytes{host="nas"}'';
                  cmp = "gt";
                  threshold = 80;
                  description = "ZFS pool capacity is above 80%; plan capacity before performance and free-space headroom deteriorate.";
                }
                {
                  uid = "nas-smart-failed";
                  title = "NAS disk SMART health failed";
                  expr = ''smartctl_device_smart_status{host="nas"}'';
                  threshold = 1;
                  noDataState = "OK";
                  severity = "critical";
                  for = "5m";
                  description = "Disk {{ $labels.device }} reports a failed SMART health check. Sleeping disks may not report until awake.";
                }
                {
                  uid = "nas-scrub-overdue";
                  title = "NAS ZFS scrub overdue or never recorded";
                  expr = ''time() - (homelab_zfs_scrub_last_completed_timestamp_seconds or on(host,pool) (0 * zfs_pool_health{host="nas",pool="main"}))'';
                  cmp = "gt";
                  threshold = 3888000;
                  description = "No completed scheduled scrub recorded for pool main in 45 days. The first deployment needs a completed scrub to establish history.";
                }
                {
                  uid = "nas-dataset-unmounted";
                  title = "NAS encrypted homelab dataset is not mounted";
                  expr = "homelab_dataset_mounted";
                  threshold = 1;
                  severity = "critical";
                  for = "10m";
                  description = "Unlock and mount the encrypted homelab dataset; services and backups depend on it.";
                }
                {
                  uid = "nas-storage-metrics-stale";
                  title = "NAS storage health collection is stale";
                  expr = "time() - homelab_storage_last_collection_timestamp_seconds";
                  cmp = "gt";
                  threshold = 900;
                  for = "5m";
                  description = "NAS storage metrics have not updated in 15 minutes. Check nas-storage-metrics.service.";
                }
                {
                  uid = "service-probe-failed";
                  title = "Critical service health probe failed";
                  expr = ''probe_success{job="blackbox"}'';
                  threshold = 1;
                  severity = "critical";
                  for = "5m";
                  description = "Health probe for {{ $labels.service }} ({{ $labels.instance }}) is failing. This is separate from exporter scrape availability.";
                }
                {
                  uid = "service-tls-expiry";
                  title = "Service TLS certificate expires within 14 days";
                  expr = ''probe_ssl_earliest_cert_expiry{job="blackbox"} - time()'';
                  threshold = 1209600;
                  description = "Certificate for {{ $labels.service }} expires within 14 days. Check ACME renewal.";
                }
                {
                  uid = "homelab-critical-unit-failed";
                  title = "Homelab systemd service failed";
                  expr = ''node_systemd_unit_state{job="nodes",state="failed",name!~"restic-backups-.*"}'';
                  cmp = "gt";
                  threshold = 0;
                  for = "5m";
                  description = "Unit {{ $labels.name }} has failed on {{ $labels.host }}.";
                }
                {
                  uid = "node-textfile-errors";
                  title = "Node textfile collector failed";
                  expr = "node_textfile_scrape_error";
                  cmp = "gt";
                  threshold = 0;
                  for = "5m";
                  description = "Node textfile metrics are unreadable or invalid on {{ $labels.host }}.";
                }
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
