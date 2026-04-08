{ inputs, den, ... }:
{
  flake-file.inputs.nixos-hardware.url = "github:nixos/nixos-hardware";
  flake-file.inputs.nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

  den.aspects.haseeb.provides.framework = {
    includes = [
      den.aspects.desktop
      den.aspects.gaming
      den.aspects.social

      
    ];

    homeManager = { lib, ... }: {
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
          { id = "Bluetooth"; displayMode = "icon"; }
          { id = "Brightness"; displayMode = "onhover"; }
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
    ];

    nixos = { config, pkgs, ... }: {
      imports = [
        ./hardware-configuration.nix
        ./disks.nix
        inputs.nixos-facter-modules.nixosModules.facter
        { config.facter.reportPath = ./facter.json; }
        inputs.nixos-hardware.nixosModules.framework-13-7040-amd
      ];

      sops.secrets = {
        user_password = {
          sopsFile = ./secrets.yaml;
          neededForUsers = true;
        };
      };

      users.users.haseeb = {
        hashedPasswordFile = config.sops.secrets.user_password.path;
        extraGroups = [ "wheel" ];
      };

      boot = {
        kernelParams = [ "rd.luks=no" ];
        initrd.systemd = {
          extraBin.jq = "${pkgs.jq}/bin/jq";
          services.check-pcrs = {
            script = ''
              echo "Checking PCR 15 value"
              if [[ $(systemd-analyze pcrs 15 --json=short | jq -r ".[0].sha256") != "caf33e79c645b65849256238a11fa68ae197e5cb89730c463c1cdf1d9128376f" ]] ; then
                echo "PCR 15 check failed"
                exit 1
              else
                echo "PCR 15 check succeeded"
              fi
            '';
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            unitConfig.DefaultDependencies = "no";
            after = [ "cryptsetup.target" ];
            before = [ "sysroot.mount" ];
            requiredBy = [ "sysroot.mount" ];
          };
        };
      };

      # Persist secure boot keys
      environment.persistence."/persist".directories = [ "/etc/secureboot" ];

      networking.hostName = "framework";
      system.stateVersion = "23.11";
    };
  };
}
