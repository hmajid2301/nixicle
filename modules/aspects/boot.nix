{ den, ... }:
{
  flake-file.inputs.lanzaboote.url = "github:nix-community/lanzaboote";

  den.aspects.boot = {
    nixos = { lib, pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        efibootmgr
        efitools
        efivar
        fwupd
        sbctl
      ];

      boot = {
        resumeDevice = "/dev/disk/by-label/nixos";
        initrd.systemd.enable = true;
        initrd.systemd.emergencyAccess = true;
        loader = {
          efi.canTouchEfiVariables = true;
          systemd-boot = {
            enable = lib.mkDefault true;
            configurationLimit = 50;
            editor = false;
          };
        };
      };

      # btrfs FIEMAP workaround for hibernate
      systemd.services.systemd-logind.environment.SYSTEMD_BYPASS_HIBERNATION_MEMORY_CHECK = "1";
      systemd.services.systemd-hibernate.environment.SYSTEMD_BYPASS_HIBERNATION_MEMORY_CHECK = "1";

      services.fwupd.enable = true;
    };
  };

  den.aspects.boot-secure = {
    includes = [ den.aspects.boot ];

    nixos = { lib, ... }: {
      boot = {
        lanzaboote = {
          enable = true;
          pkiBundle = "/etc/secureboot";
          autoGenerateKeys.enable = true;
          autoEnrollKeys = {
            enable = true;
            autoReboot = true;
          };
        };
        loader.systemd-boot.enable = lib.mkForce false;
      };

      # fwupd-efi needs root to read Secure Boot keys when signing
      systemd.services.fwupd-efi.serviceConfig.User = lib.mkForce "root";
    };
  };
}
