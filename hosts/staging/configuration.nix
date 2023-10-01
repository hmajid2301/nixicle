{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix

    ../../nixos/global
    ../../nixos/users/haseeb.nix

    ../../nixos/optional/auto-upgrade.nix
    ../../nixos/optional/attic.nix
    ../../nixos/optional/backup.nix
    ../../nixos/optional/docker.nix
    ../../nixos/optional/fonts.nix
    ../../nixos/optional/pipewire.nix
    #../../nixos/optional/quietboot.nix
    ../../nixos/optional/vfio.nix
    ../../nixos/optional/vpn.nix
    ../../nixos/optional/grub.nix
    ../../nixos/optional/ephemeral.nix

    #../nixos/optional/wireless.nix
  ];

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  networking = {
    hostName = "staging";
  };

  system.stateVersion = "23.05";
}
