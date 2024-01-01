{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.nixos.fingerprint;
in {
  options.modules.nixos.fingerprint = {
    enable = mkEnableOption "Enable fingerprint auth";
  };

  config = mkIf cfg.enable {
    services = {
      fprintd = {
        enable = true;
      };
    };

    security.pam.services = {
      swaylock.fprintAuth = true;
      login.fprintAuth = true;
      sudo.fprintAuth = true;
    };
  };
}
