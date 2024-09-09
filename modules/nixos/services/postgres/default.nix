{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.nixicle.postgresql;
in {
  options.services.nixicle.postgresql = {
    enable = mkEnableOption "Enable postgresql";
  };

  config = mkIf cfg.enable {
    services = {
      postgresql = {
        enable = true;
        package = pkgs.postgresql_16_jit;
      };
      postgresqlBackup = {
        enable = true;
        location = "/mnt/share/postgresql";
        backupAll = true;
        startAt = "*-*-* 10:00:00";
      };
    };
  };
}
