# Storage recovery for the migrated NAS.
#
# The TrueNAS "main" raidz2 pool is imported by name (see default.nix
# boot.zfs.extraPools). TrueNAS stored the pool mountpoint as `/main` and
# mounted it via `altroot=/mnt`, so datasets appeared at `/mnt/main/main`.
# On a plain NixOS import there is no altroot, so without intervention the
# datasets would mount at `/main/main` — breaking the NFS export, SMB share
# and every client that expects `/mnt/main`.
#
# The oneshot below rewrites the mountpoints to the `/mnt/main` layout before
# `zfs-mount.service` runs. It is idempotent (only sets when different) and
# safe: changing a `mountpoint` property does not touch data.
#
# Pool dataset properties (compression=lz4, atime=off, xattr=sa,
# aclmode=discard) live on the pool itself and are not re-declared here.
# `main/main-encrypted` is aes-256-gcm / passphrase / prompt — unlocked
# manually after boot (see runbook); the property change here works even
# while it is locked.
{ pkgs, ... }:
{
  systemd.services.zfs-nas-mountpoints = {
    description = "Normalise NAS 'main' pool mountpoints to /mnt/main layout";
    after = [ "zfs-import-main.service" ];
    before = [ "zfs-mount.service" ];
    wantedBy = [ "zfs-mount.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -eu
      zfs=${pkgs.zfs}/bin/zfs
      set_mp() {
        ds="$1"; want="$2"
        cur=$("$zfs" get -H -o value mountpoint "$ds" 2>/dev/null || echo "")
        if [ -n "$cur" ] && [ "$cur" != "$want" ]; then
          "$zfs" set -u mountpoint="$want" "$ds"
        fi
      }
      set_mp main /mnt/main
      set_mp main/main /mnt/main/main
      set_mp main/main-encrypted /mnt/main/main-encrypted
    '';
  };

  # Path-compatibility dirs for the noauto ix-apps datasets and app recovery.
  # (main/main and main/main-encrypted mount over /mnt/main/... via ZFS.)
  systemd.tmpfiles.rules = [
    "d /mnt/main 0755 root root -"
    "d /mnt/.ix-apps 0755 root root -"
    "d /mnt/.ix-apps/app_mounts 0755 root root -"
    "d /mnt/.ix-apps/app_configs 0755 root root -"
  ];

  # /mnt/recovery is a scratch area for read-only inspection after install.
  fileSystems."/mnt/recovery" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "mode=0755"
      "size=2G"
    ];
  };
}
