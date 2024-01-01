{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.nixos.power;
in {
  options.modules.nixos.power = {
    enable = mkEnableOption "Enable battery power";
  };

  config = mkIf cfg.enable {
    services.power-profiles-daemon.enable = false;
    services.tlp.enable = true;
  };
}
