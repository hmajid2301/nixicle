{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.roles.gamedev;
in {
  options.roles.gaming = with types; {
    enable = mkBoolOpt false "Whether or not to manage game dev configuration";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      godot4
      aseprite
    ];
  };
}
