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
    media-server.enable = true;
    vpn.enable = true;
    nixicle = {
      nfs.enable = true;
      n8n.enable = true;
      gitlab-runner.enable = true;
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

  boot = {
    supportedFilesystems = lib.mkForce ["btrfs"];
    kernelPackages = pkgs.linuxPackages_latest;
    resumeDevice = "/dev/disk/by-label/nixos";

    initrd = {
      supportedFilesystems = ["nfs"];
      kernelModules = ["nfs"];
    };

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = "2099999999";
      "fs.inotify.max_user_instances" = "2099999999";
      "fs.inotify.max_queued_events" = "2099999999";
    };
  };

  system.stateVersion = "23.11";
}
