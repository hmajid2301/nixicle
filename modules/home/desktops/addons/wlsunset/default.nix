{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.desktops.addons.wlsunset;
in {
  options.desktops.addons.wlsunset = {
    enable = mkEnableOption "Enable wlsunset night light";
  };

  config = mkIf cfg.enable {
    services.wlsunset = {
      enable = true;
      latitude = "51.5072";
      longitude = "-0.1275";
    };
  };
}
