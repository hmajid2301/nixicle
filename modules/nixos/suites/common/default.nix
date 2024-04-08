{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.suites.common;
in {
  options.suites.common = {
    enable = mkEnableOption "Enable common configuration";
  };

  config = mkIf cfg.enable {
    nix.enable = true;
    hardware = {
      audio.enable = true;
      bluetooth.enable = true;
      networking.enable = true;
    };

    services = {
      openssh.enable = true;
    };

    security = {
      sops.enable = true;
      yubikey.enable = true;
    };

    system = {
      boot.enable = true;
      fonts.enable = true;
      locale.enable = true;
    };
  };
}
