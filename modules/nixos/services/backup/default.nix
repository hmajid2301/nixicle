{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.backup;

  btrfsSnapshotScript = pkgs.writeShellScript "btrfs-snapshot" ''
    set -euo pipefail

    SNAPSHOT_DIR="${cfg.backupPath}/btrfs-snapshots"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)

    mkdir -p "$SNAPSHOT_DIR"

    ${concatMapStringsSep "\n" (subvol: ''
      echo "Creating snapshot of ${subvol}..."
      ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot -r "${subvol}" "$SNAPSHOT_DIR/$(basename ${subvol})-$TIMESTAMP" || {
        echo "WARNING: Failed to snapshot ${subvol}"
      }
    '') cfg.btrfsSubvolumes}

    ${pkgs.btrfs-progs}/bin/btrfs subvolume list "$SNAPSHOT_DIR" 2>/dev/null | \
      awk '{print $NF}' | \
      sort -r | \
      tail -n +$((${toString cfg.keepBackups} * ${toString (length cfg.btrfsSubvolumes)} + 1)) | \
      xargs -I {} ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$SNAPSHOT_DIR/{}" 2>/dev/null || true

    echo "BTRFS snapshot completed"
  '';
in
{
  options.services.nixicle.backup = {
    enable = mkEnableOption "Enable automated backups";

    backupPath = mkOption {
      type = types.str;
      default = "/var/backup";
      description = "Root path for storing backups";
    };

    keepBackups = mkOption {
      type = types.int;
      default = 4;
      description = "Number of backups to keep locally";
    };

    schedule = mkOption {
      type = types.str;
      default = "weekly";
      description = "Backup schedule (daily, weekly, etc.)";
    };

    btrfsSubvolumes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/persist" ];
      description = "BTRFS subvolumes to snapshot";
    };

    s3 = {
      enable = mkEnableOption "Enable S3 backups (Backblaze B2)";

      bucket = mkOption {
        type = types.str;
        example = "my-backup-bucket";
        description = "S3/B2 bucket name";
      };

      endpoint = mkOption {
        type = types.str;
        default = "s3.us-west-000.backblazeb2.com";
        description = "S3 endpoint URL";
      };

      paths = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "/var/backup" ];
        description = "Paths to upload to S3";
      };
    };
  };

  config = mkIf cfg.enable {
    services.postgresqlBackup = mkIf config.services.postgresql.enable {
      enable = true;
      location = "${cfg.backupPath}/postgresql";
      startAt = cfg.schedule;
      backupAll = true;
      compression = "zstd";
    };

    systemd.services.btrfs-snapshot = mkIf (cfg.btrfsSubvolumes != [ ]) {
      description = "BTRFS Snapshot Backup";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${btrfsSnapshotScript}";
        User = "root";
      };
    };

    systemd.timers.btrfs-snapshot = mkIf (cfg.btrfsSubvolumes != [ ]) {
      description = "BTRFS Snapshot Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
      };
    };

    systemd.services.s3-backup = mkIf cfg.s3.enable {
      description = "S3 Backup Upload";
      after = [ "network-online.target" "postgresqlBackup.service" "btrfs-snapshot.service" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "s3-backup-upload" ''
          set -euo pipefail

          export AWS_ACCESS_KEY_ID=$(cat ${config.sops.secrets.s3_access_key.path})
          export AWS_SECRET_ACCESS_KEY=$(cat ${config.sops.secrets.s3_secret_key.path})

          ${concatMapStringsSep "\n" (path: ''
            echo "Syncing ${path} to s3://${cfg.s3.bucket}/${config.networking.hostName}/$(basename ${path})/"
            ${pkgs.awscli2}/bin/aws s3 sync \
              --endpoint-url https://${cfg.s3.endpoint} \
              "${path}" \
              "s3://${cfg.s3.bucket}/${config.networking.hostName}/$(basename ${path})/" \
              --delete
          '') cfg.s3.paths}

          echo "S3 backup completed"
        '';
      };
    };

    systemd.timers.s3-backup = mkIf cfg.s3.enable {
      description = "S3 Backup Upload Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
      };
    };

    sops.secrets.s3_access_key = mkIf cfg.s3.enable {
      sopsFile = ../../secrets.yaml;
    };

    sops.secrets.s3_secret_key = mkIf cfg.s3.enable {
      sopsFile = ../../secrets.yaml;
    };

    environment.persistence."/persist" = mkIf config.system.impermanence.enable {
      directories = [
        {
          directory = cfg.backupPath;
          user = "root";
          group = "root";
          mode = "0700";
        }
      ];
    };
  };
}
