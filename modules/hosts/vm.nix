{ den, ... }:
{
  den.aspects.vm = {
    includes = [ den.aspects.impermanence ];

    nixos = { lib, pkgs, ... }: {
      imports = [
        ../../hosts/vm/hardware-configuration.nix
        ../../hosts/vm/disks.nix
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
