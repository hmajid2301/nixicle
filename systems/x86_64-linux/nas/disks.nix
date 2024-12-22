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
              name = "storage1";
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-f"];
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
              name = "storage2";
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-f"];
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
              name = "storage3";
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-f"];
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
              name = "storage4";
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-f"];
              };
            };
          };
        };
      };
    };
  };
}
