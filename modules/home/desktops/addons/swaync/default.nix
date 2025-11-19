{delib, ...}:
delib.module {
  name = "desktops-addons-swaync";

  options.desktops.addons.swaync = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, ...}:
  with lib;
  let
    cfg = config.desktops.addons.swaync;
  in
  mkIf cfg.enable {
    services.swaync = {
      enable = true;
      settings = {};
      style = builtins.readFile ./swaync.css;
    };
  };
}
