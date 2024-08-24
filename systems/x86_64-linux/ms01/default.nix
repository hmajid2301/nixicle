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
    tandoor.enable = true;
    media-server.enable = true;
    vpn.enable = true;
    nixicle = {
      authentik.enable = true;
      monitoring.enable = true;
      netdata.enable = true;
      gitlab-runner.enable = true;
      gotify.enable = true;
      nfs.enable = true;
      # plausible.enable = true;
      # paperless.enable = true;
      photoprism.enable = true;
      postgresql.enable = true;
      syncthing.enable = true;
      traefik.enable = true;
    };
  };

  roles = {
    kubernetes = {
      enable = true;
      role = "agent";
    };
  };

  # networking.interfaces.enp1s0.wakeOnLan.enable = true;

  topology.self = {
    hardware.info = "MS01";
  };

  boot = {
    supportedFilesystems = lib.mkForce ["btrfs"];
    kernelPackages = pkgs.linuxPackages_latest;
    resumeDevice = "/dev/disk/by-label/nixos";

    initrd = {
      supportedFilesystems = ["nfs"];
      kernelModules = ["nfs"];
    };
  };

  system.stateVersion = "23.11";
}
