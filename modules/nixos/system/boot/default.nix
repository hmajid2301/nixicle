{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.nixicle) mkBoolOpt;

  cfg = config.system.boot;
in
{
  options.system.boot = {
    enable = mkBoolOpt false "Whether or not to enable booting.";
    plymouth = mkBoolOpt false "Whether or not to enable plymouth boot splash.";
    secureBoot = mkBoolOpt false "Whether or not to enable secure boot.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      with pkgs;
      [
        efibootmgr
        efitools
        efivar
        fwupd
        sbctl
      ]
      ++ lib.optionals cfg.secureBoot [ sbctl ];

    boot = {
      resumeDevice = "/dev/disk/by-label/nixos";

      # TODO: if plymouth on
      kernelParams = lib.optionals cfg.plymouth [
        "quiet"
        "splash"
        "loglevel=3"
        "udev.log_level=0"
      ];
      # initrd.verbose = lib.optionals cfg.plymouth false;
      # consoleLogLevel = lib.optionals cfg.plymouth 0;
      initrd.systemd.enable = true;
      initrd.systemd.emergencyAccess = true;
      lanzaboote = mkIf cfg.secureBoot {
        enable = true;
        pkiBundle = "/etc/secureboot";

        autoGenerateKeys.enable = true;
        autoEnrollKeys = {
          enable = true;
          autoReboot = true;
        };
      };

      loader = {
        efi = {
          canTouchEfiVariables = true;
        };

        systemd-boot = {
          enable = !cfg.secureBoot;
          configurationLimit = 50;
          editor = false;
        };
      };

      plymouth = {
        enable = cfg.plymouth;
      };
    };

    services.fwupd.enable = true;

    # fwupd-efi service needs root access to read Secure Boot keys when signing
    systemd.services.fwupd-efi = mkIf cfg.secureBoot {
      serviceConfig = {
        # Remove sandboxing to allow access to /etc/secureboot keys
        User = lib.mkForce "root";
      };
    };

    environment.persistence = mkIf (cfg.secureBoot && config.system.impermanence.enable) {
      "/persist" = {
        directories = [
          "/etc/secureboot"
        ];
      };
    };
  };
}
