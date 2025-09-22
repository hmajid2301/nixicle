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

  sops.secrets = {
    cloudflared_ms01 = {
      sopsFile = ../../../modules/nixos/services/secrets.yaml;
    };

    gitlab_runner_env_ms01 = {
      sopsFile = ../../../modules/nixos/services/secrets.yaml;
    };

    b2_application_key = {
      sopsFile = ../../../modules/nixos/services/secrets.yaml;
    };
  };

  fileSystems."/mnt/n1" = {
    device = "/dev/disk/by-uuid/a85dfa14-38bf-4cb8-af7e-d1a977a3df0c";
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

    nixicle = {
      atticd.enable = true;
      authentik.enable = true;
      audiobookshelf.enable = true;
      couchdb.enable = true;
      deluge.enable = true;
      homepage.enable = true;
      gitea.enable = true;
      gitlab-runner = {
        enable = true;
        sopsFile = config.sops.secrets.gitlab_runner_env_ms01.path;
      };
      immich.enable = true;
      jellyfin.enable = true;
      logging.enable = true;
      monitoring.enable = true;
      minio.enable = true;
      navidrome.enable = true;
      netdata.enable = true;
      otel-collector.enable = true;
      # paperless.enable = true;
      postgresql.enable = true;
      redis.enable = true;
      traefik.enable = true;

      s3-backup = {
        enable = true;
        endpoint = "s3.us-west-004.backblazeb2.com";
        bucket = "Majiy00Homelab";
        accessKeyId = "0043ba7ac168efb000000000c";
        secretKeyFile = config.sops.secrets.b2_application_key.path;
        paths = [
          "/var/lib/postgresql"
        ];
        schedule = "daily";
      };
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

  roles.kubernetes = {
    enable = true;
    role = "agent";
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

  networking = {
    hostName = "ms01";

    interfaces = {
      enp2s0f0.wakeOnLan.enable = true;
      enp2s0f1.wakeOnLan.enable = true;
      enp87s0.wakeOnLan.enable = true;
      enp89s0.wakeOnLan.enable = true;
    };
  };

  system.stateVersion = "23.11";
}
