{delib, ...}:
delib.module {
  name = "development-containers-docker";

  options.development.containers.docker = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.development.containers.docker;
  in
  mkIf cfg.enable {
    home.packages = with pkgs; [
      arion
      docker
      docker-compose
      dive
      amazon-ecr-credential-helper
    ];
  };
}
