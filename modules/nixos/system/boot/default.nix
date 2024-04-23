{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.nixicle) mkBoolOpt;

  cfg = config.system.boot;
in {
  options.system.boot = {
    enable = mkBoolOpt false "Whether or not to enable booting.";
    plymouth = mkBoolOpt false "Whether or not to enable plymouth boot splash.";
    secureBoot = mkBoolOpt false "Whether or not to enable secure boot.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      [
        efibootmgr
        efitools
        efivar
        fwupd
      ]
      ++ lib.optionals cfg.secureBoot [sbctl];

    boot = {
      # TODO: if plymouth on
      kernelParams = lib.optionals cfg.plymouth ["quiet" "splash" "loglevel=3" "udev.log_level=0"];
      initrd.verbose = lib.optionals cfg.plymouth false;
      consoleLogLevel = lib.optionals cfg.plymouth 0;
      initrd.systemd.enable = true;

      lanzaboote = mkIf cfg.secureBoot {
        enable = true;
        pkiBundle = "/etc/secureboot";
      };

      loader = {
        efi = {
          canTouchEfiVariables = true;
        };

        systemd-boot = {
          enable = !cfg.secureBoot;
          configurationLimit = 20;
          editor = false;
        };
      };

      plymouth = {
        enable = cfg.plymouth;
        theme = "catppuccin-mocha";
        themePackages = [(pkgs.catppuccin-plymouth.override {variant = "mocha";})];
      };
    };

    services.fwupd.enable = true;
  };
}
