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
  cfg = config.development.containers.podman;
in
{
  options.development.containers.podman = with types; {
    enable = mkBoolOpt false "Whether or not to manage podman";
  };
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      arion
      podman
      podman-compose
      podman-tui
    ];
  };
}
