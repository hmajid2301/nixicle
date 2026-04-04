{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
  ];

  networking.hostName = "vm";
  system.boot.plymouth = lib.mkForce false;

  home-manager.backupFileExtension = "backup";

  system.impermanence.enable = true;

  services.ssh.enable = true;

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
  security.sudo.wheelNeedsPassword = false;

  roles = {
    desktop.enable = true;
    desktop.addons = {
      gnome.enable = false;
      niri.enable = true;
    };
  };

  boot = {
    supportedFilesystems = lib.mkForce [ "btrfs" ];
    kernelPackages = pkgs.linuxPackages_latest;
    resumeDevice = "/dev/disk/by-label/nixos";
  };

  system.stateVersion = "23.11";
}
