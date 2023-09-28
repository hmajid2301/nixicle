{
  imports = [
    ./hardware-configuration.nix
    ./users/haseeb
    ./disks.nix

    ../../nixos/global

    ../../nixos/optional/auto-upgrade.nix
    ../../nixos/optional/attic.nix
    ../../nixos/optional/backup.nix
    ../../nixos/optional/docker.nix
    ../../nixos/optional/fonts.nix
    ../../nixos/optional/pipewire.nix
    ../../nixos/optional/greetd.nix
    ../../nixos/optional/quietboot.nix
    ../../nixos/optional/vfio.nix
    ../../nixos/optional/vpn.nix
    ../../nixos/optional/grub.nix
    #../../nixos/optional/ephemeral.nix

    #../nixos/optional/wireless.nix
  ];

  networking = {
    hostName = "staging";
  };

  system.stateVersion = "23.05";
}
