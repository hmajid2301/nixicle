{
  pkgs,
  ...
}:
let
  # restic excludes match against the full path as passed (verified
  # empirically with restic 0.19.1): "/media" alone would match nothing
  # and a bare "media" would match any path component (it once dropped
  # paperless/media). Anchor on the exact backup path instead.
  backupPath = "/mnt/main/main-encrypted/homelab/.zfs/snapshot/restic-pre";
in
{
  system.backup.objects.homelab = {
    # Backup the restic-pre snapshot, never the live dataset mid-write.
    paths = [ backupPath ];
    exclude = [
      "${backupPath}/media"
      "${backupPath}/.Trash*"
    ];
    # Write-only B2 key cannot delete; retention is applied manually
    # with the master key on the quarterly maintenance schedule.
    pruneOpts = [ ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
    backupPrepareCommand = "${pkgs.zfs}/bin/zfs snapshot main/main-encrypted/homelab@restic-pre";
    backupCleanupCommand = "${pkgs.zfs}/bin/zfs destroy main/main-encrypted/homelab@restic-pre";
  };

  systemd.services."restic-backups-homelab" = {
    # Locked dataset = skipped run, not a failed run.
    unitConfig.ConditionPathIsMountPoint = "/mnt/main/main-encrypted/homelab";
  };

  # Manual runs, restore and prune drills need the binary on the box.
  environment.systemPackages = [ pkgs.restic ];
}
