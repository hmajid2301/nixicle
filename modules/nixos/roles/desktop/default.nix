{
  lib,
  config,
  ...
}:
with lib;

let
  cfg = config.roles.desktop;
in
{
  options.roles.desktop = {
    enable = mkEnableOption "Enable desktop configuration";
  };

  config = mkIf cfg.enable {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    roles = {
      common.enable = true;
    };

    hardware = {
      audio.enable = true;
      bluetooth.enable = true;
      logitechMouse.enable = true;
      zsa.enable = true;
    };

    services = {
      nixicle.avahi.enable = true;
      backup.enable = true;
      vpn.enable = true;
      virtualisation.docker.enable = true;
    };

    system = {
      boot.plymouth = true;
    };

    cli.programs = {
      nh.enable = true;
      nix-ld.enable = true;
    };

    user = {
      name = "haseeb";
      initialPassword = "1";
    };
  };
}
