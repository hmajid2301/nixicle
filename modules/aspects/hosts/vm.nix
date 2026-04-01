# vm host aspect — extends the auto-created den.aspects.vm.
{ den, ... }:
{
  den.aspects.vm = {
    includes = [
      den.aspects.desktop
      den.provides.primary-user
    ];

    nixos = { pkgs, lib, ... }: {
      system.boot.plymouth = lib.mkForce false;
      home-manager.backupFileExtension = "backup";
      system.impermanence.enable = true;
      services.ssh.enable = true;
      services.qemuGuest.enable = true;
      services.spice-vdagentd.enable = true;
      security.sudo.wheelNeedsPassword = false;

      roles.desktop = {
        enable = true;
        addons = {
          gnome.enable = false;
          niri.enable = true;
        };
      };

      boot = {
        supportedFilesystems = lib.mkForce [ "btrfs" ];
        kernelPackages = pkgs.linuxPackages_latest;
        resumeDevice = "/dev/disk/by-label/nixos";
      };

      system.stateVersion = "23.11";
    };
  };
}
