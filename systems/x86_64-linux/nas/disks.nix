{
  disko.devices = {
    disk = {
      system = {
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
                ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-L" "nixos" "-f"];
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = ["subvol=root" "compress=zstd" "noatime"];
                  };
                  "/home" = {
                    mountpoint = "/home";
                    mountOptions = ["subvol=home" "compress=zstd" "noatime"];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = ["subvol=nix" "compress=zstd" "noatime"];
                  };
                  "/persist" = {
                    mountpoint = "/persist";
                    mountOptions = ["subvol=persist" "compress=zstd" "noatime"];
                  };
                  "/log" = {
                    mountpoint = "/var/log";
                    mountOptions = ["subvol=log" "compress=zstd" "noatime"];
                  };
                  "/swap" = {
                    mountpoint = "/swap";
                    swap.swapfile.size = "64G";
                  };
                };
              };
            };
          };
        };
      };

      storage1 = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            storage = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-L" "storage" "-f"];
              };
            };
          };
        };
      };

      storage2 = {
        type = "disk";
        device = "/dev/sdb";
        content = {
          type = "gpt";
          partitions = {
            storage = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [
                  "-f"
                  "-L"
                  "storage"
                  "-d"
                  "raid5"
                  "-m"
                  "raid5"
                  "/dev/sda1"
                  "/dev/sdc1"
                  "/dev/sdd1"
                ];
                mountpoint = "/storage";
                subvolumes = {
                  "/data" = {
                    mountpoint = "/storage/data";
                    mountOptions = ["subvol=data" "compress=zstd" "noatime"];
                  };
                  "/media" = {
                    mountpoint = "/storage/media";
                    mountOptions = ["subvol=media" "compress=zstd" "noatime"];
                  };
                  "/backups" = {
                    mountpoint = "/storage/backups";
                    mountOptions = ["subvol=backups" "compress=zstd" "noatime"];
                  };
                };
              };
            };
          };
        };
      };

      storage3 = {
        type = "disk";
        device = "/dev/sdc";
        content = {
          type = "gpt";
          partitions = {
            storage = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-L" "storage" "-f"];
              };
            };
          };
        };
      };

      storage4 = {
        type = "disk";
        device = "/dev/sdd";
        content = {
          type = "gpt";
          partitions = {
            storage = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-L" "storage" "-f"];
              };
            };
          };
        };
      };
    };
  };
}
