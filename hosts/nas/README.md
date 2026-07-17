# nas

Recovery-first NixOS host for migrating a TrueNAS box onto a clean boot disk.

## Important

- `hosts/nas/disks.nix` must contain **only** the new boot disk.
- Do **not** put any of the old ZFS data disks into `disko`.
- Import the old pools read-only first from a trusted live environment.
- Rebuild apps fresh against recovered datasets; do not trust old TrueNAS runtime state.

## Before first install

1. Replace `REPLACE_ME_BOOT_DISK` in `hosts/nas/disks.nix` with the stable `/dev/disk/by-id/...` of the new boot disk.
2. Replace `hosts/nas/hardware-configuration.nix` with `nixos-generate-config` output from the target machine.
3. Optionally update `networking.hostId` if you already know the hostid you want to use for ZFS operations.
4. Leave `boot.zfs.extraPools = [ ];` empty until you have inspected the recovered pools.

## Suggested recovery flow

```bash
# from trusted live environment
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,FSTYPE,MOUNTPOINTS
blkid
zpool import
zpool import -N -o readonly=on <pool>
zpool status <pool>
zfs list -r <pool>
```

After the new system is installed and booted:

```bash
sudo zpool import
sudo zpool import -N -o readonly=on <pool>
sudo zfs load-key <pool>/<dataset>   # if encrypted
sudo zfs mount <pool>/<dataset>
```

Only switch to writable imports once you've confirmed the pool, datasets, and paths are correct.
