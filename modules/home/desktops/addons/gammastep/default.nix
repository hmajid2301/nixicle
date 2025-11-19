{delib, ...}:
delib.module {
  name = "desktops-addons-gammastep";

  options.desktops.addons.gammastep = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, ...}:
  with lib;
  let
    cfg = config.desktops.addons.gammastep;
  in
  mkIf cfg.enable {
    services.gammastep = {
      enable = true;
      provider = "geoclue2";
      temperature = {
        day = 6000;
        night = 4600;
      };
      settings = {
        general.adjustment-method = "wayland";
      };
    };
  };
}
