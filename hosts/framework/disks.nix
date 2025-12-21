{
  disko.devices = {
    disk = {
      nvme0n1 = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              label = "boot";
              name = "ESP";
              size = "512M";
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
                  allowDiscards = true;
                  crypttabExtraOpts = [
                    "token-timeout=10"
                    "tpm2-device=auto"
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

                    # Create the blank snapshot for impermanence rollback
                    btrfs subvolume snapshot -r /mnt/root /mnt/root-blank

                    # Pre-create critical directories in /persist for first boot
                    # This is essential for nixos-anywhere + impermanence to work
                    mkdir -p /mnt/persist/{root,srv,etc/nixos,etc/ssh}
                    mkdir -p /mnt/persist/var/{spool,cache,db}
                    mkdir -p /mnt/persist/var/lib/{nixos,systemd,dbus,bluetooth,NetworkManager}
                    mkdir -p /mnt/persist/var/lib/systemd/{coredump,timers,timesync}
                    mkdir -p /mnt/persist/var/db/sudo
                    mkdir -p /mnt/persist/etc/NetworkManager/system-connections

                    # Set proper permissions
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
                      swap.swapfile.size = "32G";
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

  fileSystems."/persist".neededForBoot = true;
  fileSystems."/var/log".neededForBoot = true;
}
