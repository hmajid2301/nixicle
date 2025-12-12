{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;

let
  cfg = config.system.impermanence;
in
{
  options.system.impermanence = with types; {
    enable = mkBoolOpt false "Enable impermanence - WARNING: Only use on VMs or test systems!";
  };

  config = mkIf cfg.enable {
    # Required for the rollback service to work properly
    boot.initrd.systemd.enable = true;

    security.sudo.extraConfig = ''
      # rollback results in sudo lectures after each reboot
      Defaults lecture = never
      # Preserve PATH for nix commands
      Defaults secure_path="/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin"
    '';

    programs.fuse.userAllowOther = true;

    # Create necessary directories in /persist on boot
    systemd.tmpfiles.rules = [
      "d /persist 0755 root root -"
      "d /persist/root 0700 root root -"
      "d /persist/etc/nixos 0755 root root -"
      "d /persist/srv 0755 root root -"
      "d /persist/var/spool 0755 root root -"
      "d /persist/var/lib 0755 root root -"
      "d /persist/var/lib/nixos 0755 root root -"
      "d /persist/var/lib/systemd 0755 root root -"
      "d /persist/var/lib/systemd/coredump 0755 root root -"
      "d /persist/var/lib/systemd/timers 0755 root root -"
      "d /persist/var/lib/systemd/timesync 0755 root root -"
      "d /persist/var/lib/bluetooth 0755 root root -"
      "d /persist/var/lib/NetworkManager 0755 root root -"
      "d /persist/var/lib/dbus 0755 root root -"
      "d /persist/var/cache 0755 root root -"
      "d /persist/var/db/sudo 0700 root root -"
      "d /persist/etc/NetworkManager/system-connections 0700 root root -"
      "d /persist/etc/ssh 0755 root root -"
    ];

    # Make sure critical directories exist
    system.activationScripts.impermanence = lib.mkBefore ''
      mkdir -p /persist/{root,srv,etc/nixos,etc/ssh}
      mkdir -p /persist/var/{spool,cache,db}
      mkdir -p /persist/var/lib/{nixos,systemd,dbus,bluetooth,NetworkManager}
      mkdir -p /persist/var/lib/systemd/{coredump,timers,timesync}
      mkdir -p /persist/var/db/sudo
      mkdir -p /persist/etc/NetworkManager/system-connections
    '';

    # Configure SSH to generate and use keys directly in /persist
    services.openssh.hostKeys = [
      {
        type = "ed25519";
        path = "/persist/etc/ssh/ssh_host_ed25519_key";
      }
      {
        type = "rsa";
        bits = 4096;
        path = "/persist/etc/ssh/ssh_host_rsa_key";
      }
    ];

    # This script does the actual wipe of the system
    # So if it doesn't run, the btrfs system effectively acts like a normal system
    # Taken from https://github.com/NotAShelf/nyx/blob/2a8273ed3f11a4b4ca027a68405d9eb35eba567b/modules/core/common/system/impermanence/default.nix
    boot.initrd.systemd.services.rollback = {
      description = "Rollback BTRFS root subvolume to a pristine state";
      wantedBy = [ "initrd.target" ];
      # make sure it's done after encryption and before mounting
      after = [
        "systemd-cryptsetup@enc.service"
        "systemd-cryptsetup@cryptroot.service"
      ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig = {
        Type = "oneshot";
        UMask = "0077";
      };
      script = ''
        set -euo pipefail

        echo "Starting impermanence rollback..."

        # Find the encrypted device (try common names)
        LUKS_DEVICE=""
        for device in /dev/mapper/enc /dev/mapper/cryptroot; do
          if [[ -b "$device" ]]; then
            LUKS_DEVICE="$device"
            break
          fi
        done

        if [[ -z "$LUKS_DEVICE" ]]; then
          echo "Error: No LUKS device found (tried enc, cryptroot), skipping rollback"
          exit 0
        fi

        echo "Found LUKS device: $LUKS_DEVICE"

        mkdir -p /mnt

        # Mount the btrfs root to /mnt so we can manipulate subvolumes
        if ! mount -o subvol=/ "$LUKS_DEVICE" /mnt; then
          echo "Error: Failed to mount root filesystem"
          exit 1
        fi

        # Check if root-blank snapshot exists
        if [[ ! -d "/mnt/root-blank" ]]; then
          echo "Error: /mnt/root-blank snapshot not found, skipping rollback"
          umount /mnt || true
          exit 0
        fi

        echo "Found root-blank snapshot, proceeding with rollback"

        # List and delete nested subvolumes first
        if [[ -d "/mnt/root" ]]; then
          echo "Removing nested subvolumes..."
          btrfs subvolume list -o /mnt/root | cut -f9 -d' ' | while read -r subvolume; do
            if [[ -n "$subvolume" ]]; then
              echo "Deleting /$subvolume subvolume..."
              btrfs subvolume delete "/mnt/$subvolume" || echo "Warning: Failed to delete $subvolume"
            fi
          done

          echo "Deleting /root subvolume..."
          if ! btrfs subvolume delete /mnt/root; then
            echo "Error: Failed to delete /root subvolume"
            umount /mnt || true
            exit 1
          fi
        fi

        echo "Restoring blank /root subvolume..."
        if ! btrfs subvolume snapshot /mnt/root-blank /mnt/root; then
          echo "Error: Failed to create snapshot"
          umount /mnt || true
          exit 1
        fi

        echo "Rollback completed successfully"
        umount /mnt || echo "Warning: Failed to unmount /mnt"
      '';
    };

    # Safety check: Only enable impermanence on systems that explicitly request it
    # and have proper btrfs setup with root-blank snapshot
    assertions = [
      {
        assertion = config.networking.hostName != "workstation";
        message = "ERROR: Impermanence is disabled on workstation for safety! Only use on VMs or test systems.";
      }
      {
        assertion = config.networking.hostName != "framework";
        message = "ERROR: Impermanence is disabled on framework laptop for safety! Only use on VMs or test systems.";
      }
      {
        assertion = config.fileSystems."/persist".fsType or null == "btrfs";
        message = "Impermanence requires /persist to be mounted as btrfs";
      }
      {
        assertion = builtins.any (fs: fs.mountPoint == "/" && fs.fsType == "btrfs") (
          builtins.attrValues config.fileSystems
        );
        message = "Impermanence requires root filesystem to be btrfs";
      }
    ];

    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        # Note: /home is a separate btrfs subvolume, not a bind mount
        # Note: /var/log is also a separate btrfs subvolume, not persisted here
        "/etc/nixos" # NixOS configuration for recovery
        "/srv"
        "/var/spool" # Mail and print spooling
        "/.cache/nix/"
        "/etc/NetworkManager/system-connections"
        "/etc/ssh"
        "/var/cache/"
        "/var/db/sudo/"
        # Instead of persisting all of /var/lib/, persist specific subdirectories
        "/var/lib/nixos" # Critical: UIDs/GIDs for systemd dynamic users
        "/var/lib/systemd/coredump"
        "/var/lib/systemd/timers"
        "/var/lib/systemd/timesync" # System time sync (critical for systems without RTC)
        "/var/lib/bluetooth"
        "/var/lib/NetworkManager" # Network leases and full NM state
        "/var/lib/dbus" # D-Bus machine UUID
        "/root" # Persist root user home
      ];
      files = [
        "/etc/machine-id"
        "/etc/adjtime" # System clock
      ];
    };
  };
}
