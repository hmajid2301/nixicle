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
    arr.enable = true;
    # vpn.enable = true;

    nixicle = {
      authentik.enable = true;
      audiobookshelf.enable = true;
      cloudflared.enable = true;
      deluge.enable = true;
      homepage.enable = true;
      gitea.enable = true;
      gitlab-runner.enable = true;
      gotify.enable = true;
      immich.enable = true;
      jellyfin.enable = true;
      monitoring.enable = true;
      # minio.enable = true;
      navidrome.enable = true;
      netdata.enable = true;
      nfs.enable = true;
      paperless.enable = true;
      # plausible.enable = true;
      # photoprism.enable = true;
      postgresql.enable = true;
      syncthing.enable = true;
      traefik.enable = true;
    };
  };

  roles = {
    server = {
      enable = true;
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
