{delib, ...}:
delib.module {
  name = "desktops-addons-wlsunset";

  options.desktops.addons.wlsunset = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, ...}:
  with lib;
  let
    cfg = config.desktops.addons.wlsunset;
  in
  mkIf cfg.enable {
    services.wlsunset = {
      enable = true;
      latitude = "51.5072";
      longitude = "-0.1275";
    };
  };
}
