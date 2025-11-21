{
  pkgs,
  lib,
  config,
mkOpt ? null,
mkBoolOpt ? null,
enabled ? null,
disabled ? null,
  ...
}:
with lib;
 let
  cfg = config.development.containers.docker;
in {
  options.development.containers.docker = with types; {
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