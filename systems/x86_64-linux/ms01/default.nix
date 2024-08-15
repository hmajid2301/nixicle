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
    nixicle = {
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

  environment.systemPackages = with pkgs; [
    cifs-utils
  ];

  fileSystems."/mnt/share" = {
    device = "//192.168.1.73/Data";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    in [
      "${automount_opts},credentials=/etc/nixos/smb-secrets"
      "uid=root"
      "gid=media"
      "file_mode=0664"
      "dir_mode=0775"
    ];
  };

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
