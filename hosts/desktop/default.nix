{
  inputs,
  den,
  ...
}:
{
  flake-file.inputs.nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

  den.aspects.haseeb.provides.desktop = {
    includes = [
      den.aspects.desktopProfile
      den.aspects.gaming
      den.aspects.social
      den.aspects.video
    ];

    homeManager = _: {
      home = {
        username = "haseeb";
        homeDirectory = "/home/haseeb";
        stateVersion = "24.05";
      };

      programs.noctalia.settings.idle = {
        pre_action_fade_seconds = 5.0;
        behavior = {
          lock = {
            timeout = 300;
            action = "lock";
          };
          screen-off = {
            timeout = 330;
            action = "screen_off";
          };
          suspend = {
            timeout = 1800;
            action = "lock_and_suspend";
          };
        };
      };
    };
  };

  den.aspects.desktop = {
    includes = [
      den.aspects.performance-max
      den.aspects.nfs-nas
      den.aspects.impermanence
      den.aspects.boot-secure
      den.aspects.tailscale
      den.aspects.kvm
      den.aspects.searx
      den.aspects.gitlab-runner
    ];

    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        imports = [
          ./hardware-configuration.nix
          ./disks.nix
          inputs.nixos-facter-modules.nixosModules.facter
          { config.facter.reportPath = ./facter.json; }
        ];

        sops.defaultSopsFile = ./secrets.yaml;
        sops.secrets = {
          user_password.neededForUsers = true;
          searx_secret_key = { };
          gitlab_runner_env = { };
        };

        users = {
          groups.media.gid = 3000;
          users.haseeb = {
            hashedPasswordFile = config.sops.secrets.user_password.path;
            extraGroups = [
              "media"
              "i2c"
            ];
          };
          extraGroups.docker.members = [ "haseeb" ];
        };

        boot = {
          kernelParams = [ "resume_offset=533760" ];
          kernel.sysctl."net.ipv4.ip_forward" = 1;
        };

        networking.hostName = "desktop";

        virtualisation.docker = {
          enable = true;
          enableOnBoot = true;
          autoPrune.enable = true;
          storageDriver = "btrfs";
          rootless = {
            enable = true;
            setSocketVariable = true;
          };
        };

        environment.systemPackages = with pkgs; [ docker-compose ];

        fileSystems."/mnt/homelab".options = lib.mkForce [
          "nfsvers=4"
          "noatime"
          "nofail"
          "x-systemd.automount"
          "x-systemd.idle-timeout=60"
          "x-systemd.device-timeout=5s"
          "x-systemd.mount-timeout=5s"
        ];

        fileSystems."/mnt/homelab/homelab".options = lib.mkForce [
          "nfsvers=4"
          "noatime"
          "nofail"
          "x-systemd.automount"
          "x-systemd.idle-timeout=60"
          "x-systemd.device-timeout=5s"
          "x-systemd.mount-timeout=5s"
          "x-systemd.requires=mnt-homelab.mount"
          "x-systemd.after=mnt-homelab.mount"
        ];

        system.stateVersion = "24.05";
      };
  };
}
