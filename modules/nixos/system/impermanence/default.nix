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
    enable = mkBoolOpt false "Enable impermanence";
  };

  config = mkIf cfg.enable {
    # This script does the actual wipe of the system
    # So if it doesn't run, the btrfs system effectively acts like a normal system
    boot.initrd.systemd.services.rollback = mkIf cfg.enable {
      description = "Rollback BTRFS root subvolume to a pristine state";
      wantedBy = ["initrd.target"];
      # make sure it's done after encryption
      # i.e. LUKS/TPM process
      after = ["systemd-cryptsetup@enc.service"];
      # mount the root fs before clearing
      before = ["sysroot.mount"];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /mnt/root-blank

        # We first mount the btrfs root to /mnt
        # so we can manipulate btrfs subvolumes.
        mount -o subvol=/ /dev/mapper/cryptroot /mnt

        # While we're tempted to just delete /root and create
        # a new snapshot from /root-blank, /root is already
        # populated at this point with a number of subvolumes,
        # which makes `btrfs subvolume delete` fail.
        # So, we remove them first.
        #
        # /root contains subvolumes:
        # - /root/var/lib/portables
        # - /root/var/lib/machines

        btrfs subvolume list -o /mnt/root |
          cut -f9 -d' ' |
          while read subvolume; do
            echo "deleting /$subvolume subvolume..."
            btrfs subvolume delete "/mnt/$subvolume"
          done &&
          echo "deleting /root subvolume..." &&
          btrfs subvolume delete /mnt/root

        echo "restoring blank /root subvolume..."
        btrfs subvolume snapshot /mnt/root-blank /mnt/root


        # Once we're done rolling back to a blank snapshot,
        # we can unmount /mnt and continue on the boot process.
        umount /mnt
      '';
    };

    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/home/haseeb"
        "/.cache/nix/"
        "/etc/NetworkManager/system-connections"
        "/etc/ssh" # I need to persist ssh keys, this persists a bit more, persising only keys broke permissions
        "/var/cache/"
        "/var/lib/bluetooth"
        "/var/lib/cups"
        "/var/lib/docker" # TODO: do not persist docker on server
        "/var/lib/flatpak"
        "/var/lib/fprint"
        "/var/lib/libvirt"
      ];
      files = [
        "/etc/machine-id"
        "/var/lib/NetworkManager/secret_key"
        "/var/lib/NetworkManager/seen-bssids"
        "/var/lib/NetworkManager/timestamps"
      ];
    };
  };
}
