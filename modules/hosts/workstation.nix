{ inputs, den, pkgs, ... }:
{
  den.aspects.haseeb.provides.workstation = {
    includes = [
      den.aspects.desktop
      den.aspects.gaming
      den.aspects.social
      den.aspects.video
    ];

    homeManager = { ... }: {
      home = {
        username = "haseeb";
        homeDirectory = "/home/haseeb";
        stateVersion = "24.05";
      };

      desktops = {
        niri.enable = true;
        addons = {
          noctalia.enable = true;
          swayidle = {
            enable = true;
            timeouts = {
              lock = 300;
              dpms = 330;
              suspend = 0;
              hibernate = 0;
            };
          };
        };
      };
    };
  };

  den.aspects.workstation = {
    includes = [
      den.aspects.nfs-truenas
      den.aspects.impermanence
      den.aspects.boot-secure
      den.aspects.tailscale
      den.aspects.kvm
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
          ../../hosts/workstation/hardware-configuration.nix
          ../../hosts/workstation/disks.nix
          inputs.nixos-facter-modules.nixosModules.facter
          { config.facter.reportPath = ../../hosts/workstation/facter.json; }
        ];

        sops.secrets = {
          user_password = {
            sopsFile = ../../hosts/workstation/secrets.yaml;
            neededForUsers = true;
          };
        };

        users.users.haseeb.hashedPasswordFile = config.sops.secrets.user_password.path;

        users.groups.media.gid = 3000;
        users.users.haseeb.extraGroups = [ "media" ];

        boot.kernelParams = [ "resume_offset=533760" ];

        virtualisation.docker = {
          enable = true;
          enableOnBoot = true;
          autoPrune.enable = true;
          storageDriver = "btrfs";
          rootless = {
            enable = true;
            setSocketVariable = true;
            daemon.settings.dns = [
              "1.1.1.1"
              "8.8.8.8"
            ];
          };
        };

        users.extraGroups.docker.members = [ "haseeb" ];

        environment.systemPackages = with pkgs; [
          docker-compose
        ];

        environment.persistence."/persist".directories = [
          "/etc/secureboot"
          {
            directory = "/var/lib/docker";
            user = "root";
            group = "root";
            mode = "0755";
          }
        ];

        boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

        networking.hostName = "workstation";
        system.stateVersion = "24.05";
      };
  };
}
