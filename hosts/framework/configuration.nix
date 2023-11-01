{ inputs, ... }: {
  imports = [
    inputs.hardware.nixosModules.framework-12th-gen-intel
    inputs.hyprland.nixosModules.default
    inputs.disko.nixosModules.disko

    ./hardware-configuration.nix
    ./disks.nix

    ../../nixos/global
    ../../nixos/users/haseeb.nix

    ../../nixos/optional/auto-upgrade.nix
    ../../nixos/optional/avahi.nix
    ../../nixos/optional/backup.nix
    ../../nixos/optional/fingerprint.nix
    ../../nixos/optional/docker.nix
    ../../nixos/optional/fonts.nix
    ../../nixos/optional/pipewire.nix
    ../../nixos/optional/greetd.nix
    ../../nixos/optional/quietboot.nix
    ../../nixos/optional/vfio.nix
    ../../nixos/optional/vpn.nix
    ../../nixos/optional/pam.nix
    ../../nixos/optional/grub.nix
  ];

  networking = {
    hostName = "framework";
  };

  system.stateVersion = "23.05";
}
