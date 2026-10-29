_: {
  den = {
    default.nixos =
      { lib, ... }:
      {
        options.system.backup.objects = lib.mkOption {
          default = { };
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                paths = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };
                exclude = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };
                user = lib.mkOption {
                  type = lib.types.str;
                  default = "root";
                };
                initialize = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                };
                pruneOpts = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [
                    "--keep-daily 7"
                    "--keep-weekly 4"
                    "--keep-monthly 3"
                  ];
                };
                checkOpts = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };
                timerConfig = lib.mkOption {
                  type = with lib.types; nullOr (attrsOf anything);
                  default = {
                    OnCalendar = "daily";
                    RandomizedDelaySec = "1h";
                    Persistent = true;
                  };
                };
                backupPrepareCommand = lib.mkOption {
                  type = with lib.types; nullOr lines;
                  default = null;
                };
                backupCleanupCommand = lib.mkOption {
                  type = with lib.types; nullOr lines;
                  default = null;
                };
              };
            }
          );
        };
      };

    aspects.backup-restic = {
      persist.directories = [ "/var/lib/prometheus-node-exporter-text-files" ];

      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          backupObjects = config.system.backup.objects;
          metricsDirectory = "/var/lib/prometheus-node-exporter-text-files";
          monitored = config.services.prometheus.exporters.node.enable;
          expectedBackups = lib.filterAttrs (_: backup: backup.timerConfig != null) backupObjects;
          expectedMetrics = pkgs.writeText "restic-expected.prom" (
            lib.concatMapStrings (name: ''
              restic_backup_expected{backup="${name}"} 1
            '') (lib.attrNames expectedBackups)
          );
          writeMetrics = pkgs.writeShellScript "restic-metrics" (builtins.readFile ./restic-metrics.sh);
          resticWrapped = pkgs.writeShellScriptBin "restic" ''
            exec ${pkgs.util-linux}/bin/flock /run/restic-backups-global.lock \
              ${pkgs.restic}/bin/restic "$@"
          '';
        in
        {
          sops = {
            secrets = {
              restic_password = { };
              backblaze_env = { };
              restic_repository = { };
            };
          };

          topology.self.services =
            (lib.mapAttrs (_: _: { hidden = true; }) config.services.restic.backups)
            // lib.optionalAttrs (config.services.restic.backups != { }) {
              restic = {
                name = "Restic backups";
                icon = "services.restic";
                info = "${toString (lib.length (lib.attrNames config.services.restic.backups))} repositories";
                details.repositories.text = lib.concatStringsSep "\n" (
                  lib.attrNames config.services.restic.backups
                );
              };
            }
            // lib.optionalAttrs (config.services.karakeep.enable or false) {
              karakeep = {
                hidden = lib.mkForce false;
                name = lib.mkForce "Karakeep";
                icon = lib.mkForce "services.karakeep";
              };
            };

          services.restic.backups = lib.mapAttrs (_name: backup: {
            inherit (backup)
              paths
              exclude
              user
              initialize
              pruneOpts
              timerConfig
              backupPrepareCommand
              backupCleanupCommand
              ;
            runCheck = backup.checkOpts != [ ];
            inherit (backup) checkOpts;
            package = resticWrapped;
            passwordFile = config.sops.secrets.restic_password.path;
            environmentFile = config.sops.secrets.backblaze_env.path;
            repositoryFile = config.sops.secrets.restic_repository.path;
          }) backupObjects;

          assertions = lib.mapAttrsToList (name: _: {
            assertion = builtins.match "[a-zA-Z0-9_-]+" name != null;
            message = "Backup names must be safe Prometheus label and file names: ${name}";
          }) backupObjects;

          services.prometheus.exporters.node.extraFlags = lib.mkIf monitored [
            "--collector.textfile.directory=${metricsDirectory}"
          ];

          systemd.tmpfiles.rules = lib.optionals monitored [
            "d ${metricsDirectory} 0755 root root -"
            "L+ ${metricsDirectory}/restic-expected.prom - - - - ${expectedMetrics}"
          ];

          systemd.services =
            lib.optionalAttrs monitored {
              systemd-tmpfiles-resetup.unitConfig.RequiresMountsFor = [ metricsDirectory ];
            }
            // lib.mapAttrs' (
              name: _backup:
              lib.nameValuePair "restic-backups-${name}" {
                path = [
                  pkgs.systemd
                  pkgs.coreutils
                ];
                preStart = lib.mkIf monitored (
                  lib.mkBefore ''
                    date +%s > /run/restic-backups-${name}/metrics-started
                  ''
                );
                serviceConfig.ExecStartPost = lib.mkIf monitored [
                  "+${pkgs.writeShellScript "restic-${name}-success" ''
                    export PATH=${lib.makeBinPath [ pkgs.coreutils ]}
                    ${writeMetrics} ${metricsDirectory} ${lib.escapeShellArg name} "$(cat /run/restic-backups-${name}/metrics-started)"
                  ''}"
                ];
              }
            ) backupObjects;
        };
    };
  };
}
