# nas

Recovery-first NixOS host for migrating a TrueNAS box onto a clean boot disk.

## Important

- `hosts/nas/disks.nix` must contain **only** the new boot disk.
- Do **not** put any of the old ZFS data disks into `disko`.
- Import the old pools read-only first from a trusted live environment.
- Rebuild apps fresh against recovered datasets; do not trust old TrueNAS runtime state.

## Current observed migration facts

Read-only recovery inspection found:

- old system pool: `boot-pool`
- preserved data pool: `main`
- `main` layout: 5-disk `raidz2`
- observed old pool hostid: `5e0a6087`
- important path compatibility target: `/mnt/main/main/Data`

The current boot/install target in `hosts/nas/disks.nix` is:

```text
/dev/disk/by-id/nvme-WDS100T3X0C-00SJG0_21234L802961
```

This was observed as the 1TB WD old `boot-pool` disk. Reconfirm this immediately before any destructive install.

## Before first install

1. Reconfirm the stable `/dev/disk/by-id/...` boot disk in `hosts/nas/disks.nix` still points to the intended old boot/system disk.
2. Confirm none of the `main` pool member disks appear in `hosts/nas/disks.nix`.
3. Replace `hosts/nas/hardware-configuration.nix` with `nixos-generate-config` output from the target machine if needed.
4. Confirm `networking.hostId = "5e0a6087"` is still the desired ZFS hostid.
5. Keep `/mnt/main/main/Data` path compatibility for the first recovery pass.

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
