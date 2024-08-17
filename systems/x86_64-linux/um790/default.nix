{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
  ];

  services = {
    virtualisation.podman.enable = true;
  };

  roles = {
    kubernetes = {
      enable = true;
      role = "server";
    };
  };

  networking.interfaces.enp1s0.wakeOnLan.enable = true;

  topology.self = {
    hardware.info = "UM790";
  };

  boot = {
    supportedFilesystems = lib.mkForce ["btrfs"];
    kernelPackages = pkgs.linuxPackages_latest;
    resumeDevice = "/dev/disk/by-label/nixos";
  };

  system.stateVersion = "23.11";
}
