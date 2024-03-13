{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disks.nix

    ../../nixos
    ../../nixos/users/haseeb.nix
  ];

  networking = {
    hostName = "desktop";
  };

  modules.nixos = {
    avahi.enable = true;
    bluetooth.enable = true;
    docker.enable = true;
  };

  swapDevices = [{device = "/swap/swapfile";}];

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  boot.initrd.systemd.enable = true;
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    resumeDevice = "/dev/disk/by-label/nixos";
  };

  system.stateVersion = "23.11";
}
