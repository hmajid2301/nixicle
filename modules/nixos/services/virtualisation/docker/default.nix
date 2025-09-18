{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.virtualisation.docker;
in {
  options.services.virtualisation.docker = {
    enable = mkEnableOption "Enable docker";
  };

  config = mkIf cfg.enable {
    virtualisation = {
      docker = {
        enable = true;
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
      };
    };
  };
}