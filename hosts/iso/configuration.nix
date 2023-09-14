{ pkgs
, lib
, ...
}: {
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];

  services.openssh.enable = true;
  services.openssh.settings.passwordAuthentication = true;

  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  users.extraUsers.root.password = "nixos";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AaAeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee username@host"
  ];

  environment.systemPackages = with pkgs; [
    git
    (
      writeShellScriptBin "install" ''
        #!/usr/bin/env bash
        set -euo pipefail

        TARGET_HOST="''${1:-}"
        TARGET_USER="''${2:-haseeb}"

        if [ "$(id -u)" -eq 0 ]; then
        	echo "ERROR! $(basename "$0") should be run as a regular user"
        	exit 1
        fi

        if [ ! -d "$HOME/dotfiles/.git" ]; then
        	git clone https://gitlab.com/hmajid2301/dotfiles.git "$HOME/dotfiles"
        fi

        mkdir "$HOME/dotfiles/"

        if [[ -z "$TARGET_HOST" ]]; then
        	echo "ERROR! $(basename "$0") requires a hostname as the first argument"
        	echo "       The following hosts are available"
        	ls -1 nixos/*/default.nix | cut -d'/' -f2 | grep -v iso
        	exit 1
        fi

        if [ ! -e "hosts/$TARGET_HOST/disks.nix" ]; then
        	echo "ERROR! $(basename "$0") could not find the required nixos/$TARGET_HOST/disks.nix"
        	exit 1
        fi

        # Check if the machine we're provisioning expects a keyfile to unlock a disk.
        # If it does, generate a new key, and write to a known location.
        if grep -q "data.keyfile" "hosts/$TARGET_HOST/disks.nix"; then
        	echo -n "$(head -c32 /dev/random | base64)" > /tmp/data.keyfile
        fi

        echo "WARNING! The disks in $TARGET_HOST are about to get wiped"
        echo "         NixOS will be re-installed"
        echo "         This is a destructive operation"
        echo
        read -p "Are you sure? [y/N]" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
        	sudo true

        	sudo nix run github:nix-community/disko \
        		--extra-experimental-features "nix-command flakes" \
        		--no-write-lock-file \
        		-- \
        		--mode zap_create_mount \
        		"nixos/$TARGET_HOST/disks.nix"

        	sudo nixos-install --flake "~/dotfiles#$TARGET_HOST"

        	# If there is a keyfile for a data disk, put copy it to the root partition and
        	# ensure the permissions are set appropriately.
        	if [[ -f "/tmp/data.keyfile" ]]; then
        		sudo cp /tmp/data.keyfile /mnt/etc/data.keyfile
        		sudo chmod 0400 /mnt/etc/data.keyfile
        	fi
        fi
      ''
    )
  ];
}
