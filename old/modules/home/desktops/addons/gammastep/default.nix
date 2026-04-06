{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.desktops.addons.gammastep;
in {
  options.desktops.addons.gammastep = {
    enable = mkEnableOption "Enable gammastep night light";
  };

  config = mkIf cfg.enable {
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
