{
  disko.devices = {
    disk = {
      # Boot/system disk ONLY. The five 4TB `main` raidz2 members must never
      # appear here. Observed 1TB WD during read-only recovery; reconfirm the
      # by-id resolves to the intended boot disk before any destructive run.
      boot = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-WDS100T3X0C-00SJG0_21234L802961";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              label = "boot";
              name = "ESP";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "umask=0077"
                  "dmask=0077"
                  "fmask=0177"
                ];
              };
            };
            luks = {
              size = "100%";
              label = "luks";
              content = {
                type = "luks";
                name = "cryptroot";
                passwordFile = "/tmp/disk-encryption.key";
                extraOpenArgs = [
                  "--allow-discards"
                  "--perf-no_read_workqueue"
                  "--perf-no_write_workqueue"
                ];
                settings = {
                  crypttabExtraOpts = [
                    "token-timeout=10"
                    "tpm2-device=auto"
                    "tpm2-pcrs=0+2+7+15"
                    "tpm2-measure-pcr=yes"
                    "x-initrd.attach"
                  ];
                };
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-L"
                    "nixos"
                    "-f"
                  ];
                  postCreateHook = ''
                    mount -t btrfs /dev/disk/by-label/nixos /mnt

                    # Blank snapshot for impermanence rollback
                    btrfs subvolume snapshot -r /mnt/root /mnt/root-blank

                    # Pre-create critical /persist dirs for first boot
                    mkdir -p /mnt/persist/{root,srv,etc/nixos,etc/ssh}
                    mkdir -p /mnt/persist/var/{spool,cache,db}
                    mkdir -p /mnt/persist/var/lib/{nixos,systemd,dbus,bluetooth,NetworkManager}
                    mkdir -p /mnt/persist/var/lib/systemd/{coredump,timers,timesync}
                    mkdir -p /mnt/persist/var/db/sudo
                    mkdir -p /mnt/persist/etc/NetworkManager/system-connections
                    mkdir -p /mnt/persist/etc/secureboot

                    # NAS service state that must survive impermanence rollback
                    mkdir -p /mnt/persist/var/lib/samba
                    mkdir -p /mnt/persist/var/lib/nfs

                    chmod 700 /mnt/persist/root
                    chmod 700 /mnt/persist/var/db/sudo
                    chmod 700 /mnt/persist/etc/NetworkManager/system-connections

                    umount /mnt
                  '';
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [
                        "subvol=root"
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [
                        "subvol=home"
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "subvol=nix"
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = [
                        "subvol=persist"
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/log" = {
                      mountpoint = "/var/log";
                      mountOptions = [
                        "subvol=log"
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/swap" = {
                      mountpoint = "/swap";
                      mountOptions = [
                        "noatime"
                        "compress=no"
                      ];
                      swap.swapfile.size = "16G";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  fileSystems = {
    "/persist".neededForBoot = true;
    "/var/log".neededForBoot = true;
    "/home".neededForBoot = true;
  };
}
