{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.roles.common;
in {
  options.roles.common = {
    enable = mkEnableOption "Enable common configuration";
  };

  config = mkIf cfg.enable {
    hardware = {
      networking.enable = true;
    };

    services = {
      ssh.enable = true;
    };

    security = {
      sops.enable = true;
      yubikey.enable = true;
    };

    system = {
      nix.enable = true;
      boot.enable = true;
      locale.enable = true;
    };
    styles.stylix.enable = true;
  };
}
