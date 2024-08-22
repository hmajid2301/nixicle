{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.postgresql;
in {
  options.services.nixicle.postgresql = {
    enable = mkEnableOption "Enable postgresql";
  };

  config = mkIf cfg.enable {
    services.postgresql = {
      enable = true;
    };
  };
}
