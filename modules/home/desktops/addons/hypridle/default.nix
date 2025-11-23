{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.desktops.addons.hypridle;
in
{
  options.desktops.addons.hypridle = with types; {
    enable = mkBoolOpt false "Whether to enable the hypridle";
  };

  config = mkIf cfg.enable {
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
          lock_cmd = "pidof hyprlock || hyprlock ";
        };

        listener = [
          {
            timeout = 300;
            on-timeout = "loginctl lock-session ";
          }
          {
            timeout = 330;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            timeout = 1800;
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };
  };
}
