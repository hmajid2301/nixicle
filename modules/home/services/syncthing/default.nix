{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.syncthing;
in {
  options.services.nixicle.syncthing = {
    enable = mkEnableOption "Enable syncthing service";
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      tray = true;
      extraOptions = ["--gui-address=127.0.0.1:8384"];
    };
  };
}
