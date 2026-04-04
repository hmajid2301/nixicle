{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.desktops.addons.hypridle;

  # Detect which compositor and addons are being used
  isNiri = config.desktops.niri.enable or false;
  isHyprland = config.desktops.hyprland.enable or false;
  isNoctalia = config.desktops.addons.noctalia.enable or false;

  # Compositor-specific commands
  dpmsOn = if isHyprland then "hyprctl dispatch dpms on"
           else if isNiri then "niri msg action power-on-monitors"
           else "echo 'No compositor-specific dpms on command'";

  dpmsOff = if isHyprland then "hyprctl dispatch dpms off"
            else if isNiri then "niri msg action power-off-monitors"
            else "echo 'No compositor-specific dpms off command'";

  lockCmd = if isHyprland then "pidof hyprlock || hyprlock"
            else if (isNiri && isNoctalia) then "noctalia-shell ipc call lockScreen lock"
            else "loginctl lock-session";
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
          after_sleep_cmd = dpmsOn;
          lock_cmd = lockCmd;
        };

        listener = [
          {
            timeout = 300;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 330;
            on-timeout = dpmsOff;
            on-resume = dpmsOn;
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
