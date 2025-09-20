{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.cli.programs.docker;
in {
  options.cli.programs.docker = with types; {
    enable = mkBoolOpt false "Whether or not to manage docker";
  };
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      arion
      docker
      docker-compose
      dive
      amazon-ecr-credential-helper
    ];
  };
}