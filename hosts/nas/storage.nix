# Storage recovery for the migrated NAS.
#
# The TrueNAS "main" raidz2 pool is imported by name (see default.nix
# boot.zfs.extraPools). This file only carries recovery-first helpers and
# the path-compatibility tmpfiles entries that preserve the old layout
# clients (NFS, SMB, apps) expect.
#
# Observed dataset properties on TrueNAS "main" and child datasets:
#   compression = lz4
#   atime      = off
#   xattr      = sa
#   aclmode    = discard
# These stay encoded on the existingpool itself and are not re-declared here.
#
# Encrypted dataset observed:
#   main/main-encrypted  encryption=aes-256-gcm  keyformat=passphrase  keylocation=prompt
# Keep unlock manual after boot; do not put the passphrase in the Nix store.
{ ... }:
{
  # Preserve the TrueNAS client/app path layout on first recovery.
  systemd.tmpfiles.rules = [
    "d /mnt/main 0755 root root -"
    "d /mnt/main/main 0755 root root -"
    "d /mnt/main/main/Data 0755 root root -"
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