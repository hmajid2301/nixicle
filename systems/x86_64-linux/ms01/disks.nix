{
  disko.devices = let
    disk = id: {
      type = "disk";
      device = "/dev/nvme${id}n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            priority = 100;
            # Hetzner
            start = "2M";
            size = "500M";
            # Hetzner's Debian installation was using "EFI System" as the partition code for the ESP mdadm raid1 members.
            # so far _this_ is not working, however it did for Hetzner.
            type = "EF00";
            content = {
              type = "mdraid";
              name = "esp";
            };
          };

          # boot = {
          #   priority = 101;
          #   size = "100%";
          #   content = {
          #     type = "mdraid";
          #     name = "boot";
          #   };
          # };

          rootfs = {
            size = "100%";
            content = {
              type = "mdraid";
              name = "rootfs";
            };
          };
        };
      };
    };
  in {
    disk = {
      sda = disk "0";
      sdb = disk "1";
      sdc = disk "2";
    };

    mdadm = {
      esp = {
        type = "mdadm";
        level = 1;
        metadata = "1.0";
        content = {
          type = "filesystem";
          # hetzner
          format = "vfat";
          extraArgs = [
            "-F"
            "16"
          ];
          # FIXME: it should be possible to use /boot/efi here and leave /boot on the btrfs
          mountpoint = "/boot";
          mountOptions = ["umask=0077"];
        };
      };

      # boot = {
      #   type = "mdadm";
      #   level = 1;
      #   content = {
      #     type = "filesystem";
      #     format = "ext3";
      #     mountpoint = "/boot";
      #   };
      # };

      rootfs = {
        type = "mdadm";
        level = 0;
        content = {
          type = "btrfs";
          extraArgs = ["-f"]; # Override existing partition
          subvolumes = {
            # Subvolume name is different from mountpoint
            "/rootfs" = {
              mountpoint = "/";
            };
            "/nix" = {
              mountOptions = ["noatime"];
              mountpoint = "/nix";
            };
          };
        };
      };
    };
  };
}
