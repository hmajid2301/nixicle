{delib, ...}:
delib.module {
  name = "roles-gamedev";

  options.roles.gamedev = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.roles.gamedev;
  in
  mkIf cfg.enable {
    home.packages = with pkgs; [
      godot_4
      aseprite
    ];
  };
}
