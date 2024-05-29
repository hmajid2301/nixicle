{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
  ];

  roles = {
    kubernetes = {
      enable = true;
      role = "agent";
    };
  };

  systemd.services.NetworkManager-wait-online.enable = false;
  security.sudo.wheelNeedsPassword = false;

  boot = {
    supportedFilesystems = lib.mkForce ["btrfs"];
    kernelPackages = pkgs.linuxPackages_latest;
    resumeDevice = "/dev/disk/by-label/nixos";
  };

  system.stateVersion = "23.11";
}
