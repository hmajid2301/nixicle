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
