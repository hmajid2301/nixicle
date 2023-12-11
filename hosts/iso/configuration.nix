{ pkgs
, config
, lib
, ...
}: {
  imports = [
    ../../nixos/global

    ../../nixos/optional/fonts.nix
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  nix.extraOptions = "experimental-features = nix-command flakes";

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];

  networking = {
    hostName = "iso";
  };

  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  home-manager.users.nixos = import ./home.nix;
  users.extraUsers.root.password = "nixos";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AaAeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee username@host"
  ];

  # TODO: gnome power settings do not turn off screen
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  services.qemuGuest.enable = true;
  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";

  environment.systemPackages = with pkgs; [
    sbctl
    git
    gum
    (
      writeShellScriptBin "rescue" ''
        #!/usr/bin/env bash
        set -euo pipefail

        gum "device name"

        sudo mkdir -p /mnt/{dev,proc,sys,boot}
        sudo mount -o bind /dev /mnt/dev
        sudo mount -o bind /proc /mnt/proc
        sudo mount -o bind /sys /mnt/sys
        sudo chroot /mnt /nix/var/nix/profiles/system/activate
        sudo chroot /mnt /run/current-system/sw/bin/bash

        sudo mount /dev/vda1 /mnt/boot
        sudo cryptsetup open /dev/vda3 cryptroot
        sudo mount /dev/mapper/cryptroot /mnt/

        sudo nixos-enter
      ''
    )
    (
      writeShellScriptBin "nix_installer"
        ''
          #!/usr/bin/env bash
          set -euo pipefail
          gsettings set org.gnome.desktop.session idle-delay 0
          gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

          if [ "$(id -u)" -eq 0 ]; then
          	echo "ERROR! $(basename "$0") should be run as a regular user"
          	exit 1
          fi

          if [ ! -d "$HOME/dotfiles/.git" ]; then
          	git clone https://gitlab.com/hmajid2301/dotfiles.git "$HOME/dotfiles"
          fi

          TARGET_HOST=$(ls -1 ~/dotfiles/hosts/*/configuration.nix | cut -d'/' -f6 | grep -v iso | gum choose)

          if [ ! -e "$HOME/dotfiles/hosts/$TARGET_HOST/disks.nix" ]; then
          	echo "ERROR! $(basename "$0") could not find the required $HOME/dotfiles/hosts/$TARGET_HOST/disks.nix"
          	exit 1
          fi

          gum confirm  --default=false \
          "🔥 🔥 🔥 WARNING!!!! This will ERASE ALL DATA on the disk $TARGET_HOST. Are you sure you want to continue?" 

          echo "Partitioning Disks"
          sudo nix run github:nix-community/disko \
          --extra-experimental-features "nix-command flakes" \
          --no-write-lock-file \
          -- \
          --mode zap_create_mount \
          "$HOME/dotfiles/hosts/$TARGET_HOST/disks.nix"

          #echo "Creating blank volume"
          #sudo btrfs subvolume snapshot -r /mnt/ /mnt/root-blank

          #echo "Set up attic binary cache"
          #attic use prod || true

          sudo nixos-install --flake "$HOME/dotfiles#$TARGET_HOST" 
        ''
    )
  ];
}
