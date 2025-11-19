{delib, ...}:
delib.module {
  name = "development-containers-podman";

  options.development.containers.podman = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.development.containers.podman;
  in
  mkIf cfg.enable {
    home.packages = with pkgs; [
      arion
      podman
      podman-compose
      podman-tui
    ];
  };
}
