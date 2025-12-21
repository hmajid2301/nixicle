{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.nixicle.mongodb;
in {
  options.services.nixicle.mongodb = {
    enable = mkEnableOption "MongoDB database server";
  };

  config = mkIf cfg.enable {
    services.mongodb = {
      enable = true;
      package = pkgs.mongodb-7_0;
    };

    # Persistence configuration for impermanent systems
    environment.persistence = mkIf config.system.impermanence.enable {
      "/persist" = {
        directories = [
          # MongoDB data directory
          {
            directory = "/var/lib/mongodb";
            user = "mongodb";
            group = "mongodb";
            mode = "0755";
          }
        ];
      };
    };
  };
}