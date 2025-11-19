{delib, ...}:
delib.module {
  name = "roles-gaming";

  options.roles.gaming = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.roles.gaming;
  in
  mkIf cfg.enable {
    programs.mangohud = {
      enable = false;
      enableSessionWide = true;
      settings = {
        cpu_load_change = true;
      };
    };

    home.packages = with pkgs; [
      lutris
      bottles
    ];
  };
}
