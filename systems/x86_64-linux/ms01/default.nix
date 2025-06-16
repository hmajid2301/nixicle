{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
  ];

  sops.secrets.cloudflared_ms01 = {
    sopsFile = ../../../modules/nixos/services/secrets.yaml;
  };

  fileSystems."/mnt/n1" = {
    device = "/dev/nvme1n1p1";
    fsType = "ext4";
    options = [
      "defaults"
      "noatime"
    ];
  };

  fileSystems."/mnt/n2" = {
    device = "/dev/nvme2n1p1";
    fsType = "ext4";
    options = [
      "defaults"
      "noatime"
    ];
  };

  services = {
    cloudflared = {
      enable = true;
      tunnels = {
        "ec0b6af0-a823-4616-a08b-b871fd2c7f58" = {
          credentialsFile = config.sops.secrets.cloudflared_ms01.path;
          default = "http_status:404";
        };
      };
    };

    ollama.acceleration = lib.mkForce "cuda";
  };

  services = {
    tandoor.enable = true;
    arr.enable = true;
    # vpn.enable = true;

    nixicle = {
      authentik.enable = true;
      atuin.enable = true;
      audiobookshelf.enable = true;
      couchdb.enable = true;
      deluge.enable = true;
      homepage.enable = true;
      gitea.enable = true;
      gitlab-runner.enable = true;
      immich.enable = true;
      jellyfin.enable = true;
      logging.enable = true;
      monitoring.enable = true;
      minio.enable = true;
      navidrome.enable = true;
      netdata.enable = true;
      #nfs.enable = true;
      smb.enable = true;
      paperless.enable = true;
      postgresql.enable = true;
      redis.enable = true;
      traefik.enable = true;
      ollama.enable = true;
    };

    traefik = {
      dynamicConfigOptions = {
        http = {
          routers = {
            api = {
              entryPoints = [ "websecure" ];
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

  topology.self = {
    hardware.info = "MS01";
  };

  boot = {
    supportedFilesystems = lib.mkForce [ "btrfs" ];
    kernelPackages = pkgs.linuxPackages_latest;
    resumeDevice = "/dev/disk/by-label/nixos";

    initrd = {
      supportedFilesystems = [ "nfs" ];
      kernelModules = [ "nfs" ];
    };
  };

  system.stateVersion = "23.11";
}
