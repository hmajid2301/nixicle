{ pkgs
, lib
, ...
}: {
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;

  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  users.extraUsers.root.password = "nixos";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AaAeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee username@host"
  ];

  programs.direnv.package = true;
  programs.direnv.nix-direnv.enable = true;

  services.xserver = {
    layout = "gb";
    xkbVariant = "";
  };
  console.keyMap = "uk";

  environment.systemPackages = with pkgs; [
    git
    (
      writeShellScriptBin "nix_installer" ''
        #!/usr/bin/env bash
        set -euo pipefail

        TARGET_HOST="''${1:-}"

        if [ "$(id -u)" -eq 0 ]; then
        	echo "ERROR! $(basename "$0") should be run as a regular user"
        	exit 1
        fi

        if [ ! -d "$HOME/dotfiles/.git" ]; then
        	git clone https://gitlab.com/hmajid2301/dotfiles.git "$HOME/dotfiles"
        fi

        if [[ -z "$TARGET_HOST" ]]; then
        	echo "ERROR! $(basename "$0") requires a hostname as the first argument"
        	echo "       The following hosts are available"
        	ls -1 ~/dotfiles/hosts/*/configuration.nix | cut -d'/' -f6 | grep -v iso
        	exit 1
        fi

        if [ ! -e "$HOME/dotfiles/hosts/$TARGET_HOST/disks.nix" ]; then
        	echo "ERROR! $(basename "$0") could not find the required $HOME/dotfiles/hosts/$TARGET_HOST/disks.nix"
        	exit 1
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
        		"$HOME/dotfiles/hosts/$TARGET_HOST/disks.nix"

        	sudo btrfs subvolume create /mnt/root
        	sudo btrfs subvolume snapshot -r /mnt/root /mnt/root-blank
        	sudo nixos-install --flake "$HOME/dotfiles#$TARGET_HOST"
        fi
      ''
    )
  ];
}
