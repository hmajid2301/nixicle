{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.system.impermanence;
in {
  options.system.impermanence = with types; {
    enable = mkBoolOpt false "Enable impermanence - WARNING: Only use on VMs or test systems!";
  };

  config = mkIf cfg.enable {
    security.sudo.extraConfig = ''
      # rollback results in sudo lectures after each reboot
      Defaults lecture = never
    '';

    programs.fuse.userAllowOther = true;

    # Create necessary directories in /persist on boot
    systemd.tmpfiles.rules = [
      "d /persist 0755 root root -"
      "d /persist/home 0755 root root -"
      "d /persist/home/haseeb 0755 haseeb users -"
      "d /persist/var/lib 0755 root root -"
      "d /persist/var/log 0755 root root -"
      "d /persist/etc/NetworkManager/system-connections 0700 root root -"
    ];

    # Make sure critical directories exist
    system.activationScripts.impermanence = lib.mkBefore ''
      mkdir -p /persist/{home,var/lib,var/log,etc/NetworkManager/system-connections}
      mkdir -p /persist/home/haseeb/{Documents,Downloads,Pictures,Videos,Music,.ssh,.config,.local,.cache}
      chown haseeb:users /persist/home/haseeb
      chown -R haseeb:users /persist/home/haseeb/{Documents,Downloads,Pictures,Videos,Music,.ssh,.config,.local,.cache} 2>/dev/null || true
    '';

    # This script does the actual wipe of the system
    # So if it doesn't run, the btrfs system effectively acts like a normal system
    # Taken from https://github.com/NotAShelf/nyx/blob/2a8273ed3f11a4b4ca027a68405d9eb35eba567b/modules/core/common/system/impermanence/default.nix
    boot.initrd.systemd.services.rollback = {
      description = "Rollback BTRFS root subvolume to a pristine state";
      wantedBy = ["initrd.target"];
      # make sure it's done after encryption and before mounting
      after = ["systemd-cryptsetup@enc.service"];
      before = ["sysroot.mount"];
      unitConfig.DefaultDependencies = "no";
      serviceConfig = {
        Type = "oneshot";
        UMask = "0077";
      };
      script = ''
        set -euo pipefail

        echo "Starting impermanence rollback..."
        
        # Check if the encrypted device exists
        if [[ ! -b "/dev/mapper/enc" ]]; then
          echo "Error: /dev/mapper/enc not found, skipping rollback"
          exit 0
        fi

        mkdir -p /mnt

        # Mount the btrfs root to /mnt so we can manipulate subvolumes
        if ! mount -o subvol=/ /dev/mapper/enc /mnt; then
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
        assertion = builtins.any (fs: fs.mountPoint == "/" && fs.fsType == "btrfs") (builtins.attrValues config.fileSystems);
        message = "Impermanence requires root filesystem to be btrfs";
      }
    ];

    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        # Don't persist /home as a whole - use user-specific directories instead
        "/srv"
        "/.cache/nix/"
        "/etc/NetworkManager/system-connections"
        "/var/cache/"
        "/var/db/sudo/"
        "/var/lib/"
      ];
      files = [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
      users.haseeb = {
        directories = [
          "Documents"
          "Downloads"
          "Pictures"
          "Videos"
          "Music"
          ".ssh"
          ".config"
          ".local"
          ".cache"
        ];
        files = [
          ".bash_history"
          ".zsh_history"
        ];
      };
    };
  };
}
