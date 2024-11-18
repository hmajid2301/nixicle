{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.nixicle.redis;
in {
  options.services.nixicle.redis = {
    enable = mkEnableOption "Enable redis";
  };

  config = mkIf cfg.enable {
    services = {
      redis.servers = {
        main = {
          enable = true;
          port = 6380;
        };
      };
    };
  };
}
