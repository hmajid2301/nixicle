{
  lib,
  config,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.suites.desktop;
in {
  options.suites.desktop = {
    enable = mkEnableOption "Enable desktop configuration";
  };

  config = mkIf cfg.enable {
    suites = {
      common.enable = true;

      desktop.addons = {
        nautilus.enable = true;
      };
    };

    hardware = {
      logitechMouse.enable = true;
      zsa.enable = true;
    };

    virtualisation = {
      podman.enable = true;
    };

    services = {
      nixicle.avahi.enable = true;
      backup.enable = true;
      vpn.enable = true;
      virtualisation.podman.enable = true;
    };

    cli.programs = {
      nix-ld.enable = true;
    };

    user = {
      name = "haseeb";
      initialPassword = "1";
    };
  };
}
