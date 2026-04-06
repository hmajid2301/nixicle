{ ... }:
{
  den.aspects.hypridle = {
    homeManager =
      { config, ... }:
      let
        # Detect which compositor is active
        isNiri = config.programs.niri.enable or false;
        isHyprland = config.wayland.windowManager.hyprland.enable or false;

        dpmsOn =
          if isHyprland then "hyprctl dispatch dpms on"
          else if isNiri then "niri msg action power-on-monitors"
          else "echo 'no dpms on command'";

        dpmsOff =
          if isHyprland then "hyprctl dispatch dpms off"
          else if isNiri then "niri msg action power-off-monitors"
          else "echo 'no dpms off command'";

        lockCmd =
          if isHyprland then "pidof hyprlock || hyprlock"
          else if isNiri then "noctalia-shell ipc call lockScreen lock"
          else "loginctl lock-session";
      in
      {
        services.hypridle = {
          enable = true;
          settings = {
            general = {
              before_sleep_cmd = "loginctl lock-session";
              after_sleep_cmd = dpmsOn;
              lock_cmd = lockCmd;
            };
            listener = [
              { timeout = 300; on-timeout = "loginctl lock-session"; }
              { timeout = 330; on-timeout = dpmsOff; on-resume = dpmsOn; }
              { timeout = 1800; on-timeout = "systemctl suspend"; }
            ];
          };
        };
      };
  };
}
