{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
  ];

  networking.hostName = "vm";

  system.impermanence.enable = true;
  suites = {
    desktop.enable = true;
    desktop.addons.gnome.enable = true;
  };

  boot = {
    supportedFilesystems = lib.mkForce ["btrfs"];
    kernelPackages = pkgs.linuxPackages_latest;
    resumeDevice = "/dev/disk/by-label/nixos";
  };

  system.stateVersion = "23.11";
}
