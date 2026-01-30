{
  inputs,
  config,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }
    inputs.nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
  ];

  sops.secrets = {
    gitlab_runner_env = {
      sopsFile = ./secrets.yaml;
    };
    cloudflared = {
      sopsFile = ./secrets.yaml;
    };
    user_password = {
      sopsFile = ./secrets.yaml;
      neededForUsers = true;
    };
    b2_access_key = {
      sopsFile = ./secrets.yaml;
    };
    b2_secret_key = {
      sopsFile = ./secrets.yaml;
    };
  };

  user.passwordSecretFile = config.sops.secrets.user_password.path;

  users.groups.media = {
    gid = 3000;
  };

  users.users.haseeb.extraGroups = [ "media" ];

  system = {
    impermanence.enable = true;
    boot = {
      enable = true;
      secureBoot = true;
    };
  };

  services = {
    power-profiles-daemon.enable = true;
    virtualisation.kvm.enable = true;
    nixicle = {
      authentik.enable = true;
      atuin.enable = true;
      atticd.enable = true;
      banterbus = {
        enable = true;
        instances = {
          dev = {
            port = 8084;
            domain = "dev.banterbus.games";
          };
          prod = {
            port = 8083;
            domain = "banterbus.games";
          };
        };
      };

      # TODO: refactor this out.
      btrbk = {
        enable = true;
        instances.local = {
          onCalendar = "weekly";
          subvolumes = {
            "/persist" = {
              target = "/mnt/truenas/backups/framebox/persist";
              snapshot_dir = ".snapshots";
            };
            "/home" = {
              target = "/mnt/truenas/backups/framebox/home";
              snapshot_dir = ".snapshots";
            };
          };
          retention = {
            weekly = 2;
            monthly = 6;
          };
        };
        backblaze = {
          enable = true;
          bucket = "Majiy00Homelab";
          endpoint = "s3.us-west-004.backblazeb2.com";
          paths = [
            "/persist/.snapshots"
            "/home/.snapshots"
          ];
          onCalendar = "weekly";
        };
      };

      cloudflare = {
        enable = true;
        tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
        credentialsFile = config.sops.secrets.cloudflared.path;
      };
      crowdsec.enable = true;
      gitea.enable = true;
      gitlab-runner = {
        enable = true;
        sopsFile = config.sops.secrets.gitlab_runner_env.path;
      };

      immich = {
        enable = true;
        mediaLocation = "/mnt/homelab/homelab/immich";
      };

      karakeep.enable = true;
      llama-cpp.enable = true;
      ollama.enable = true;
      jellyfin.enable = true;
      monitoring.enable = true;
      open-webui.enable = true;
      otel-collector.enable = true;
      redis.enable = true;
      postgresql.enable = true;
      paperless = {
        enable = true;
        mediaDir = "/mnt/homelab/homelab/paperless/media";
      };

      tangled.enable = true;
      tandoor.enable = true;
      traefik.enable = true;
      tailscale.enable = true;

      # adguard.enable = true;
      # unbound.enable = true;
    };
  };

  roles = {
    desktop = {
      enable = true;
      addons = {
        niri.enable = true;
      };
    };
    gaming.enable = true;
  };

  networking.hostName = "framebox";

  # TODO: refactor this also.
  services.rpcbind.enable = true;
  fileSystems."/mnt/homelab" = {
    device = "truenas:/mnt/main/main-encrypted";
    fsType = "nfs";
    options = [
      "nfsvers=4"
      "noatime"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "x-systemd.requires=tailscaled.service"
      "x-systemd.after=tailscaled.service"
    ];
  };

  fileSystems."/mnt/truenas" = {
    device = "truenas:/mnt/main/main";
    fsType = "nfs";
    options = [
      "nfsvers=4"
      "noatime"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "x-systemd.requires=tailscaled.service"
      "x-systemd.after=tailscaled.service"
    ];
  };

  system.stateVersion = "24.05";
}
