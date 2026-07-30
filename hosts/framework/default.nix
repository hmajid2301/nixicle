{ inputs, den, ... }:
{
  flake-file.inputs.nixos-hardware.url = "github:nixos/nixos-hardware";
  flake-file.inputs.nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

  den.aspects.haseeb.provides.framework = {
    includes = [
      den.aspects.desktopProfile
      den.aspects.gaming
      den.aspects.social
      den.aspects.video
      den.aspects.iris
    ];

    homeManager =
      { lib, ... }:
      {
        home = {
          username = "haseeb";
          homeDirectory = "/home/haseeb";
          stateVersion = "24.05";
        };

        programs.noctalia-shell.settings = {
          idle = {
            enabled = true;
            screenOffTimeout = 330;
            lockTimeout = 300;
            suspendTimeout = 900;
            fadeDuration = 5;
          };
          bar.widgets.right = lib.mkBefore [
            {
              id = "Bluetooth";
              displayMode = "icon";
            }
            {
              id = "Brightness";
              displayMode = "onhover";
            }
            { id = "Battery"; }
          ];
          controlCenter.shortcuts.right = lib.mkBefore [
            { id = "PowerProfile"; }
          ];
          osd.monitors = [ "eDP-1" ];
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
          inputs.nixos-hardware.nixosModules.framework-13-7040-amd
        ];

        sops.defaultSopsFile = ./secrets.yaml;

        sops.secrets = {
          user_password = {
            neededForUsers = true;
          };
          searx_secret_key = {
            sopsFile = ../framebox/secrets.yaml;
          };
        };

        users.users.haseeb = {
          hashedPasswordFile = config.sops.secrets.user_password.path;
          extraGroups = [
            "wheel"
            "docker"
            "networkmanager"
          ];
        };

        boot = {
          initrd.systemd.enable = true;
        };

        # Disable inbound SSH on this laptop
        services.openssh.enable = lib.mkForce false;

        networking.hostName = "framework";
        system.stateVersion = "23.11";
      };
  };
}
