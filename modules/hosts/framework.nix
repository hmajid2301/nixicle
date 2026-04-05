{ inputs, den, lib, ... }:
{
  den.aspects.haseeb.provides.framework = {
    includes = [
      den.aspects.desktop
      den.aspects.gaming
      den.aspects.social

      ({ host, ... }: {
        homeManager = { ... }: {
          desktops.addons.swayidle = {
            enable = host.isLaptop;
            timeouts = {
              lock = 300;
              dpms = 330;
              suspend = 0;
              hibernate = 900;
            };
          };
        };
      })
    ];

    homeManager = { ... }: {
      home = {
        username = "haseeb";
        homeDirectory = "/home/haseeb";
        stateVersion = "24.05";
      };

      desktops = {
        niri.enable = true;
        addons.noctalia = {
          enable = true;
          laptop = true;
          settings.osd.monitors = [ "eDP-1" ];
        };
      };
    };
  };

  den.aspects.framework = {
    includes = [
      den.aspects.impermanence
      den.aspects.boot-secure
    ];

    nixos = { config, ... }: {
      imports = [
        ../../hosts/framework/hardware-configuration.nix
        ../../hosts/framework/disks.nix
        inputs.nixos-facter-modules.nixosModules.facter
        { config.facter.reportPath = ../../hosts/framework/facter.json; }
        inputs.nixos-hardware.nixosModules.framework-13-7040-amd
      ];

      sops.secrets = {
        user_password = {
          sopsFile = ../../hosts/framework/secrets.yaml;
          neededForUsers = true;
        };
      };

      users.users.haseeb.hashedPasswordFile = config.sops.secrets.user_password.path;

      security.nixicle.pcr-verification = {
        enable = true;
        expectedPcr15 = "caf33e79c645b65849256238a11fa68ae197e5cb89730c463c1cdf1d9128376f";
      };

      # Persist secure boot keys
      environment.persistence."/persist".directories = [ "/etc/secureboot" ];

      networking.hostName = "framework";
      system.stateVersion = "23.11";
    };
  };
}
