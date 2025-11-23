{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.s3-backup;
in
{
  options.services.nixicle.s3-backup = {
    enable = mkEnableOption "Enable S3-compatible backups";

    endpoint = mkOption {
      type = types.str;
      default = "s3.us-west-004.backblazeb2.com";
      description = "S3 endpoint URL";
    };

    bucket = mkOption {
      type = types.str;
      description = "S3 bucket name";
    };

    accessKeyId = mkOption {
      type = types.str;
      description = "S3 access key ID";
    };

    secretKeyFile = mkOption {
      type = types.path;
      description = "Path to file containing S3 secret key";
    };

    paths = mkOption {
      type = types.listOf types.str;
      default = [
        "/var/lib"
        "/etc"
      ];
      description = "Paths to backup";
    };

    schedule = mkOption {
      type = types.str;
      default = "daily";
      description = "Backup schedule";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.s3-backup = {
      description = "Backup to S3-compatible storage";

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        EnvironmentFile = cfg.secretKeyFile;
      };

      script = ''
        export AWS_ACCESS_KEY_ID="${cfg.accessKeyId}"
        export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
        export AWS_DEFAULT_REGION="us-west-004"

        BACKUP_DATE=$(date +%Y-%m-%d_%H-%M-%S)
        HOSTNAME=$(hostname)

        # Create tar archive
        tar -czf /tmp/backup-$HOSTNAME-$BACKUP_DATE.tar.gz ${concatStringsSep " " cfg.paths}

        # Upload to S3
        ${pkgs.awscli2}/bin/aws s3 cp \
          /tmp/backup-$HOSTNAME-$BACKUP_DATE.tar.gz \
          s3://${cfg.bucket}/backups/$HOSTNAME/backup-$HOSTNAME-$BACKUP_DATE.tar.gz \
          --endpoint-url https://${cfg.endpoint}

        # Cleanup local backup
        rm -f /tmp/backup-$HOSTNAME-$BACKUP_DATE.tar.gz

        # Keep only last 7 backups
        ${pkgs.awscli2}/bin/aws s3 ls s3://${cfg.bucket}/backups/$HOSTNAME/ \
          --endpoint-url https://${cfg.endpoint} | \
          sort | head -n -7 | awk '{print $4}' | \
          xargs -I {} ${pkgs.awscli2}/bin/aws s3 rm s3://${cfg.bucket}/backups/$HOSTNAME/{} \
          --endpoint-url https://${cfg.endpoint}
      '';
    };

    systemd.timers.s3-backup = {
      description = "Timer for S3 backup";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
      };
    };
  };
}
