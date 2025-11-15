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

  system.impermanence.enable = true;

  services.ssh.enable = true;

  # Enable QEMU guest agent for better VM integration
  services.qemuGuest.enable = true;

  # Enable SPICE vdagent for clipboard sharing between host and guest
  services.spice-vdagentd.enable = true;

  # Allow passwordless sudo for wheel group (needed for deploy-rs)
  security.sudo.wheelNeedsPassword = false;

  roles = {
    desktop.enable = true;
    desktop.addons.gnome.enable = true;
  };

  boot = {
    supportedFilesystems = lib.mkForce [ "btrfs" ];
    kernelPackages = pkgs.linuxPackages_latest;
    resumeDevice = "/dev/disk/by-label/nixos";
  };

  system.stateVersion = "23.11";
}
