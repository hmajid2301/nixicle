{delib, ...}:
delib.module {
  name = "desktops-addons-hyprpaper";

  options.desktops.addons.hyprpaper = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.desktops.addons.hyprpaper;
  in
  mkIf cfg.enable {
    services.hyprpaper = {
      enable = true;
    };
  };
}
