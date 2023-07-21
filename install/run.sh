export DISK=/dev/nvme0n1
# Format the EFI partition
mkfs.vfat -n boot "$DISK"p1

cryptsetup --verify-passphrase -v luksFormat "$DISK"p2
cryptsetup open "$DISK"p2 enc

# Creat the swap inside the encrypted partition
pvcreate /dev/mapper/enc
vgcreate lvm /dev/mapper/enc

lvcreate --size 32G --name swap lvm
lvcreate --extents 100%FREE --name root lvm

mkswap -L swap /dev/lvm/swap
mkfs.btrfs -L nixos /dev/lvm/root

swapon /dev/lvm/swap

# Then create subvolumes

mount -t btrfs /dev/lvm/root /mnt

# We first create the subvolumes outlined above:
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/persist
btrfs subvolume create /mnt/log

# We then take an empty *readonly* snapshot of the root subvolume,
# which we'll eventually rollback to on every boot.
btrfs subvolume snapshot -r /mnt/root /mnt/root-blank

umount /mnt

# Mount the directories

mount -o subvol=root,compress=zstd,noatime /dev/lvm/root /mnt

mkdir /mnt/home
mount -o subvol=home,compress=zstd,noatime /dev/lvm/root /mnt/home

mkdir /mnt/nix
mount -o subvol=nix,compress=zstd,noatime /dev/lvm/root /mnt/nix

mkdir /mnt/persist
mount -o subvol=persist,compress=zstd,noatime /dev/lvm/root /mnt/persist

mkdir -p /mnt/var/log
mount -o subvol=log,compress=zstd,noatime /dev/lvm/root /mnt/var/log

# don't forget this!
mkdir /mnt/boot
mount "$DISK"p1 /mnt/boot

nixos-generate-config --root /mnt
