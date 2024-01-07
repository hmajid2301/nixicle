{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.nixos.power;
in {
  options.modules.nixos.power = {
    enable = mkEnableOption "Enable power management apps";
  };

  config = mkIf cfg.enable {
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;
  };
}
