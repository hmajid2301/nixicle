{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.desktops.addons.wlsunset;
in
{
  options.desktops.addons.wlsunset = with types; {
    enable = mkBoolOpt false "Enable wlsunset night light";

    latitude = mkOption {
      type = str;
      default = "51.5072";
      description = "Latitude for sunset/sunrise calculation (default: London)";
    };

    longitude = mkOption {
      type = str;
      default = "-0.1275";
      description = "Longitude for sunset/sunrise calculation (default: London)";
    };

    temperature = {
      day = mkOption {
        type = int;
        default = 6500;
        description = "Daytime color temperature in Kelvin";
      };

      night = mkOption {
        type = int;
        default = 4000;
        description = "Nighttime color temperature in Kelvin";
      };
    };

    gamma = mkOption {
      type = nullOr str;
      default = null;
      description = "Gamma value (e.g., '1.0:0.8:0.8' for RGB). If null, uses default.";
    };
  };

  config = mkIf cfg.enable {
    services.wlsunset = {
      enable = true;
      latitude = cfg.latitude;
      longitude = cfg.longitude;
      temperature = {
        day = cfg.temperature.day;
        night = cfg.temperature.night;
      };
      gamma = mkIf (cfg.gamma != null) cfg.gamma;
    };

    # Override systemd service to only start with niri
    systemd.user.services.wlsunset = {
      Unit = {
        BindsTo = [ "niri.service" ];
        After = [ "niri.service" ];
        PartOf = lib.mkForce [ "niri.service" ];
      };
      Install = {
        WantedBy = lib.mkForce [ ];
      };
    };
  };
}
