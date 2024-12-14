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
      couchdb.enable = true;
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
      # paperless.enable = true;
      postgresql.enable = true;
      redis.enable = true;
      syncthing.enable = true;
      traefik.enable = true;
    };

    traefik = {
      dynamicConfigOptions = {
        http = {
          routers = {
            api = {
              entryPoints = ["websecure"];
              rule = "Host(`traefik.homelab.haseebmajid.dev`)";
              service = "api@internal";
              tls.certResolver = "letsencrypt";
            };
          };
        };
      };
    };
  };

  roles = {
    kubernetes = {
      enable = true;
      role = "server";
    };
  };

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = 1048576;
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = 1048576;
    }
  ];

  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = "8192";
  };

  # INFO: Until there is a better fix; https://github.com/NixOS/nixpkgs/issues/360592
  nixpkgs.config.permittedInsecurePackages = [
    "aspnetcore-runtime-6.0.36"
    "aspnetcore-runtime-wrapped-6.0.36"
    "dotnet-sdk-6.0.428"
    "dotnet-sdk-wrapped-6.0.428"
  ];

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
