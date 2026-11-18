{ inputs, den, ... }:
{
  flake-file.inputs.nixos-hardware.url = "github:nixos/nixos-hardware";

  den.aspects.haseeb.provides.framework = {
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

      nixicle.desktop.niri.internalDisplayScale = 1.5;

      programs.noctalia.settings = {
        osd = {
          monitors = [ "eDP-1" ];
        };
        lockscreen.fingerprint = true;
        idle = {
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
              timeout = 900;
              action = "lock_and_suspend";
            };
          };
        };
      };
    };
  };

  den.aspects.framework = {
    includes = [
      den.aspects.performance-balanced
      den.aspects.impermanence
      den.aspects.boot-secure
      den.aspects.nfs-nas
      den.aspects.searx
      den.aspects.tailscale
      den.aspects.docker
      den.aspects.ollama
    ];

    persist.directories = [ "/var/lib/fprint" ];

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        imports = [
          ./hardware-configuration.nix
          ./disks.nix
          inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3
        ];

        sops.defaultSopsFile = ./secrets.yaml;

        sops.secrets = {
          user_password = {
            neededForUsers = true;
          };
          searx_secret_key = {
            sopsFile = ./secrets.yaml;
          };
        };

        users.users.haseeb = {
          hashedPasswordFile = config.sops.secrets.user_password.path;
          extraGroups = [ "docker" ];
        };

        boot = {
          kernelPackages = pkgs.linuxPackages_latest;
          kernelParams = [ "resume_offset=533760" ];
          lanzaboote.autoEnrollKeys.includeFirmwareBuiltinKeys = true;
        };

        hardware.intelgpu.driver = "xe";
        environment.variables.RUSTICL_ENABLE = lib.mkForce "iris";

        services = {
          thermald.enable = true;
          xserver.videoDrivers = lib.mkForce [ "modesetting" ];
          openssh.openFirewall = false;
        };

        networking.hostName = "framework";
        system.stateVersion = "23.11";
      };
  };
}
