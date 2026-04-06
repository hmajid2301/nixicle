{ den, ... }:
{
  den.aspects.haseeb.provides.vm = {
    includes = [
      den.aspects.desktop
      den.aspects.gaming
    ];

    homeManager = { ... }: {
      home = {
        username = "haseeb";
        homeDirectory = "/home/haseeb";
        stateVersion = "23.11";
      };

      cli.tools.ssh.enableKeychain = false;
    };
  };

  den.aspects.vm = {
    includes = [ den.aspects.impermanence ];

    nixos = { lib, pkgs, ... }: {
      imports = [
        ./hardware-configuration.nix
        ./disks.nix
      ];

      boot.plymouth.enable = lib.mkForce false;
      home-manager.backupFileExtension = "backup";

      services.qemuGuest.enable = true;
      services.spice-vdagentd.enable = true;
      security.sudo.wheelNeedsPassword = false;

      boot = {
        supportedFilesystems = lib.mkForce [ "btrfs" ];
        kernelPackages = pkgs.linuxPackages_latest;
        resumeDevice = "/dev/disk/by-label/nixos";
      };

      networking.hostName = "vm";
      system.stateVersion = "23.11";
    };
  };
}
