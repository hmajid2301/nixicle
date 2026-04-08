{ inputs, den, pkgs, ... }:
{
  flake-file.inputs.nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

  den.aspects.haseeb.provides.workstation = {
    includes = [
      den.aspects.desktop
      den.aspects.gaming
      den.aspects.social
      den.aspects.obs
    ];

    homeManager = { pkgs, config, ... }: {
      home = {
        username = "haseeb";
        homeDirectory = "/home/haseeb";
        stateVersion = "24.05";
      };

      programs.noctalia-shell.settings.idle = {
        enabled = true;
        screenOffTimeout = 330;
        lockTimeout = 300;
        suspendTimeout = 1800;
        fadeDuration = 5;
      };
    };
  };

  den.aspects.workstation = {
    includes = [
      den.aspects.performance-max
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
          ./hardware-configuration.nix
          ./disks.nix
          inputs.nixos-facter-modules.nixosModules.facter
          { config.facter.reportPath = ./facter.json; }
        ];

        sops.secrets = {
          user_password = {
            sopsFile = ./secrets.yaml;
            neededForUsers = true;
          };
        };

        users = {
          users.haseeb.hashedPasswordFile = config.sops.secrets.user_password.path;
          groups.media.gid = 3000;
          users.haseeb.extraGroups = [ "media" ];
          extraGroups.docker.members = [ "haseeb" ];
        };

        boot = {
          kernelParams = [ "resume_offset=533760" ];
          kernel.sysctl."net.ipv4.ip_forward" = 1;
        };

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

        networking.hostName = "workstation";
        system.stateVersion = "24.05";
      };
  };
}
