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
    enable = mkBoolOpt false "Enable impermanence";
  };

  config = mkIf cfg.enable {
    boot.initrd.systemd.enable = true;

    security.sudo.extraConfig = ''
      # rollback results in sudo lectures after each reboot
      Defaults lecture = never
      # Preserve PATH for nix commands
      Defaults secure_path="/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin"
    '';

    programs.fuse.userAllowOther = true;

    systemd.tmpfiles.rules = [
      "d /persist 0755 root root -"
      "d /persist/root 0700 root root -"
      "d /persist/etc 0755 root root -"
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

    system.activationScripts = {
      "var-lib-private-permissions" = {
        deps = [ "specialfs" ];
        text = ''
          mkdir -p /persist/var/lib/private
          chmod 0700 /persist/var/lib/private
        '';
      };
      
      "impermanence" = {
        deps = [ "var-lib-private-permissions" "users" "groups" ];
        text = ''
          mkdir -p /persist/{root,srv,etc/nixos,etc/ssh}
          mkdir -p /persist/var/{spool,cache,db}
          mkdir -p /persist/var/lib/{nixos,systemd,dbus,bluetooth,NetworkManager}
          mkdir -p /persist/var/lib/systemd/{coredump,timers,timesync}
          mkdir -p /persist/var/db/sudo
          mkdir -p /persist/etc/NetworkManager/system-connections
          mkdir -p /persist/etc/ssh
          ${lib.optionalString config.system.boot.secureBoot "mkdir -p /persist/etc/secureboot"}
        '';
      };
    };

    services.openssh.hostKeys = lib.mkForce [
      {
        path = "/persist/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "/persist/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];

    # This script does the actual wipe of the system
    # So if it doesn't run, the btrfs system effectively acts like a normal system
    # Taken from https://github.com/NotAShelf/nyx/blob/2a8273ed3f11a4b4ca027a68405d9eb35eba567b/modules/core/common/system/impermanence/default.nix
    boot.initrd.systemd.services.rollback = {
      description = "Rollback BTRFS root subvolume to a pristine state";
      wantedBy = [ "initrd.target" ];
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

        if ! mount -o subvol=/ "$LUKS_DEVICE" /mnt; then
          echo "Error: Failed to mount root filesystem"
          exit 1
        fi

        if [[ ! -d "/mnt/root-blank" ]]; then
          echo "Error: /mnt/root-blank snapshot not found, skipping rollback"
          umount /mnt || true
          exit 0
        fi

        echo "Found root-blank snapshot, proceeding with rollback"

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

    assertions = [
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
        "/etc/nixos"
        "/srv"
        "/var/spool"
        "/.cache/nix/"
        "/etc/NetworkManager/system-connections"
        "/var/cache/"
        "/var/db/sudo/"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/lib/systemd/timers"
        "/var/lib/systemd/timesync"
        "/var/lib/bluetooth"
        "/var/lib/NetworkManager"
        "/var/lib/dbus"
        "/root"
      ];
      files = [
        "/etc/machine-id"
        "/etc/adjtime"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };
  };
}
