_: {
  den.aspects.monitoringAlerts = {
    nixos = { config, ... }: {
      services.grafana.provision.alerting = {
        rules.settings = {
          apiVersion = 1;
          groups = [
            {
              orgId = 1;
              name = "restic-backups";
              folder = "Backups";
              interval = "1m";
              rules = [
                {
                  uid = "restic-backup-failed";
                  title = "Restic backup service failed";
                  condition = "C";
                  for = "5m";
                  annotations = {
                    summary = "Restic backup unit {{ $labels.name }} entered failed state";
                    description = ''
                      node_systemd_unit_state{name="{{ $labels.name }}",state="failed"} has been 1 for 5m+.
                    '';
                  };
                  labels = {
                    severity = "critical";
                  };
                  data = [
                    {
                      refId = "A";
                      relativeTimeRange = {
                        from = 600;
                        to = 0;
                      };
                      datasourceUid = "prometheus";
                      model = {
                        datasource = {
                          type = "prometheus";
                          uid = "prometheus";
                        };
                        editorMode = "code";
                        expr = ''max_over_time(node_systemd_unit_state{name=~"restic-backups-.*",state="failed"}[10m])'';
                        instant = true;
                        intervalMs = 1000;
                        legendFormat = "{{name}}";
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
                            evaluator.params = [ 0 ];
                            evaluator.type = "gt";
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
                              evaluator.params = [ 0 ];
                              evaluator.type = "gt";
                              operator.type = "and";
                              query.params = [ "C" ];
                            }
                          ];
                        };
                        type = "threshold";
                      };
                    }
                  ];
                }
                {
                  # Dead-man: timers fire daily; if none triggered in 25h
                  # backups have silently stopped (timer dead, disabled, or
                  # scheduler failures). node_systemd_timer_last_trigger_seconds
                  # reads systemd's LastTriggerUSec directly, so it survives
                  # the scrape-miss problem transient "activating" states have.
                  uid = "restic-backup-not-run";
                  title = "Restic backup not run within 24h";
                  condition = "C";
                  for = "0m";
                  annotations = {
                    summary = "No restic-backups timer fired in the last 25h";
                    description = ''
                      max(node_systemd_timer_last_trigger_seconds{name=~"restic-backups-.*"}) is older than 25h.
                      Backups may have silently stopped (timer disabled, dead, or never triggered).
                    '';
                  };
                  labels = {
                    severity = "critical";
                  };
                  data = [
                    {
                      refId = "A";
                      relativeTimeRange = {
                        from = 90000;
                        to = 0;
                      };
                      datasourceUid = "prometheus";
                      model = {
                        datasource = {
                          type = "prometheus";
                          uid = "prometheus";
                        };
                        editorMode = "code";
                        expr = ''(time() - max(node_systemd_timer_last_trigger_seconds{name=~"restic-backups-.*"})) > bool 90000'';
                        instant = true;
                        intervalMs = 1000;
                        legendFormat = "__auto";
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
                            evaluator.params = [ 0 ];
                            evaluator.type = "gt";
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
                              evaluator.params = [ 0 ];
                              evaluator.type = "gt";
                              operator.type = "and";
                              query.params = [ "C" ];
                            }
                          ];
                        };
                        type = "threshold";
                      };
                    }
                  ];
                }
                {
                  # Any restic timer not in active state = no future runs
                  # scheduled; catches disabled/masked timers immediately.
                  uid = "restic-backup-timer-dead";
                  title = "Restic backup timer not active";
                  condition = "C";
                  for = "5m";
                  annotations = {
                    summary = "Restic backup timer {{ $labels.name }} is not active";
                    description = ''
                      min(node_systemd_unit_state{name=~"restic-backups-.*\\.timer",state="active"}) == 0.
                      A restic-backups timer is disabled, masked, or missing.
                    '';
                  };
                  labels = {
                    severity = "critical";
                  };
                  data = [
                    {
                      refId = "A";
                      relativeTimeRange = {
                        from = 600;
                        to = 0;
                      };
                      datasourceUid = "prometheus";
                      model = {
                        datasource = {
                          type = "prometheus";
                          uid = "prometheus";
                        };
                        editorMode = "code";
                        expr = ''min(node_systemd_unit_state{name=~"restic-backups-.*\\.timer",state="active"})'';
                        instant = true;
                        intervalMs = 1000;
                        legendFormat = "__auto";
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
                            evaluator.params = [ 1 ];
                            evaluator.type = "lt";
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
                              evaluator.params = [ 1 ];
                              evaluator.type = "lt";
                              operator.type = "and";
                              query.params = [ "C" ];
                            }
                          ];
                        };
                        type = "threshold";
                      };
                    }
                  ];
                }
                {
                  # NAS restic units have no node exporter (metrics
                  # ruled out of scope); their journald streams ship to
                  # Loki on the VPS via the otel-collector-forwarder
                  # aspect, so failure detection is log-based. restic
                  # prints "Fatal:" on repo/upload errors and systemd
                  # logs "Failed with result" when the unit dies hard
                  # (both patterns verified against real events).
                  uid = "nas-restic-backup-failed";
                  title = "NAS restic backup failed";
                  condition = "C";
                  for = "0m";
                  annotations = {
                    summary = "NAS restic-backups-homelab hit a Fatal error or failed unit";
                    description = ''
                      Fatal lines from the NAS restic stream, or a
                      "Failed with result" line for restic-backups-homelab,
                      in the last 10m (host_name="nas" in Loki).
                    '';
                  };
                  labels = {
                    severity = "critical";
                  };
                  data = [
                    {
                      refId = "A";
                      relativeTimeRange = {
                        from = 600;
                        to = 0;
                      };
                      datasourceUid = "loki";
                      model = {
                        datasource = {
                          type = "loki";
                          uid = "loki";
                        };
                        editorMode = "code";
                        expr = ''sum(count_over_time({host_name="nas",service_name=~"restic|restic-backups-homelab-.*"} |~ "Fatal" [10m])) or sum(count_over_time({host_name="nas",service_name="systemd"} |= "Failed with result" |= "restic-backups-homelab" [10m]))'';
                        instant = true;
                        intervalMs = 1000;
                        legendFormat = "__auto";
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
                            evaluator.params = [ 0 ];
                            evaluator.type = "gt";
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
                              evaluator.params = [ 0 ];
                              evaluator.type = "gt";
                              operator.type = "and";
                              query.params = [ "C" ];
                            }
                          ];
                        };
                        type = "threshold";
                      };
                    }
                  ];
                }
                {
                  # NAS dead-man over logs: restic logs "snapshot <id>
                  # saved" under service_name="restic" on every success
                  # (verified: both real snapshots in Loki). No such
                  # line in 25h covers NAS death, disabled timer, a
                  # failing restic run, and a broken log shipper. The
                  # "or vector(0)" keeps the series alive so silence
                  # evaluates to 0 instead of no-data.
                  uid = "nas-restic-backup-silent";
                  title = "NAS restic backup not run within 24h";
                  condition = "C";
                  for = "0m";
                  annotations = {
                    summary = "No NAS restic snapshot saved in the last 25h";
                    description = ''
                      count_over_time({host_name="nas",service_name="restic"} |= "snapshot" |= "saved" [25h]) == 0.
                      NAS dead, timer disabled, restic failing, or the log
                      shipper broke — silence means no completed backup.
                    '';
                  };
                  labels = {
                    severity = "critical";
                  };
                  data = [
                    {
                      refId = "A";
                      relativeTimeRange = {
                        from = 90000;
                        to = 0;
                      };
                      datasourceUid = "loki";
                      model = {
                        datasource = {
                          type = "loki";
                          uid = "loki";
                        };
                        editorMode = "code";
                        expr = ''(sum(count_over_time({host_name="nas",service_name="restic"} |= "snapshot" |= "saved" [25h])) or vector(0))'';
                        instant = true;
                        intervalMs = 1000;
                        legendFormat = "__auto";
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
                            evaluator.params = [ 1 ];
                            evaluator.type = "lt";
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
                              evaluator.params = [ 1 ];
                              evaluator.type = "lt";
                              operator.type = "and";
                              query.params = [ "C" ];
                            }
                          ];
                        };
                        type = "threshold";
                      };
                    }
                  ];
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

      sops.templates."gotify-grafana-env".content = ''
        GOTIFY_APP_TOKEN=${config.sops.placeholder.gotify_grafana_app_token}
      '';

      systemd.services.grafana.serviceConfig.EnvironmentFile = [
        config.sops.templates."gotify-grafana-env".path
      ];
    };
  };
}
