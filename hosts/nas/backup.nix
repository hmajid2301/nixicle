# Off-site backups for the NAS via Borgmatic.
#
# STATUS: scaffolded, NOT yet imported by default.nix. Enable after creating
# `hosts/nas/secrets.yaml` (see the migration note "Off-site backup" section)
# and adding `./backup.nix` to the imports list in default.nix.
#
# What it backs up: the important, non-media, hard-to-recreate state — the
# encrypted homelab app data (immich/paperless), the ix-apps stash config +
# DB, and /mnt/main/main/Data. The bulk media library is intentionally NOT in
# the borg repo (too large / re-downloadable); replicate that separately if
# wanted.
#
# Lesson baked in (jeffrescignano): the upstream borgmatic systemd unit is
# hardened so aggressively that a ZFS snapshot hook breaks. The overrides
# below loosen exactly what the ZFS hook needs.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  sops.secrets.borg_passphrase = { };
  sops.secrets.borg_ssh_key = { };

  services.borgmatic = {
    enable = true;
    settings = {
      source_directories = [
        "/mnt/main/main-encrypted/homelab/immich"
        "/mnt/main/main-encrypted/homelab/paperless"
        "/mnt/main/main/Data"
        "/mnt/.ix-apps/app_mounts/stash/config"
      ];

      repositories = [
        {
          # TODO: replace with the real rsync.net / Backblaze B2 borg repo.
          path = "ssh://REPLACE_ME@REPLACE_ME.rsync.net/./nas-borg";
          label = "offsite";
        }
      ];

      # ZFS consistency: borgmatic snapshots ZFS datasets before reading.
      zfs.zfs_command = "${pkgs.zfs}/bin/zfs";

      encryption_passcommand = "cat ${config.sops.secrets.borg_passphrase.path}";
      ssh_command = "ssh -i ${config.sops.secrets.borg_ssh_key.path}";

      keep_daily = 7;
      keep_weekly = 4;
      keep_monthly = 6;
    };
  };

  # Loosen the aggressive upstream hardening so the ZFS snapshot hook works
  # (needs /dev/zfs, host /proc, and CAP_SYS_ADMIN to create/destroy snaps).
  systemd.services.borgmatic.serviceConfig = {
    PrivateDevices = lib.mkForce false;
    ProtectProc = lib.mkForce "default";
    CapabilityBoundingSet = lib.mkForce "CAP_DAC_READ_SEARCH CAP_NET_RAW CAP_SYS_ADMIN";
    AmbientCapabilities = lib.mkForce "CAP_SYS_ADMIN";
    SystemCallFilter = lib.mkForce "";
  };
}
