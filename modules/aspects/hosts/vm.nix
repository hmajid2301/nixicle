{ den, ... }:
{
  den.aspects.vm = {
    nixos = { config, lib, pkgs, ... }: {
      imports = [
        ../../../old/hosts/vm/hardware-configuration.nix
        ../../../old/hosts/vm/disks.nix
      ];

      system.boot.plymouth = lib.mkForce false;
      home-manager.backupFileExtension = "backup";
      system.impermanence.enable = true;

      services.ssh.enable = true;
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
