{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.desktops.addons.swayidle;

  isNiri = config.desktops.niri.enable or false;
  isHyprland = config.desktops.hyprland.enable or false;
  isNoctalia = config.desktops.addons.noctalia.enable or false;

  dpmsOn =
    if isHyprland then
      "${pkgs.hyprland}/bin/hyprctl dispatch dpms on"
    else if isNiri then
      "${config.programs.niri.package}/bin/niri msg action power-on-monitors && ${pkgs.pamixer}/bin/pamixer --unmute"
    else
      "echo 'No compositor-specific dpms on command'";

  dpmsOff =
    if isHyprland then
      "${pkgs.hyprland}/bin/hyprctl dispatch dpms off"
    else if isNiri then
      "${config.programs.niri.package}/bin/niri msg action power-off-monitors && ${pkgs.pamixer}/bin/pamixer --mute"
    else
      "echo 'No compositor-specific dpms off command'";

  lockCmd =
    if isHyprland then
      "${pkgs.hyprlock}/bin/hyprlock"
    else if (isNiri && isNoctalia) then
      "${pkgs.quickshell}/bin/qs ipc --path ${config.programs.noctalia-shell.package}/share/noctalia-shell --newest call lockScreen lock"
    else
      "${pkgs.systemd}/bin/loginctl lock-session";
in
{
  options.desktops.addons.swayidle = with types; {
    enable = mkBoolOpt false "Whether to enable swayidle (compatible with older Wayland compositors)";

    timeouts = mkOption {
      type = types.attrs;
      default = {
        lock = 300;
        dpms = 330;
        suspend = 1800;
        hibernate = 0;
      };
      description = "Timeout values in seconds";
    };
  };

  config = mkIf cfg.enable {
    services.swayidle = {
      enable = true;
      events = {
        before-sleep = lockCmd;
      };
      timeouts = [
        {
          timeout = cfg.timeouts.lock;
          command = lockCmd;
        }
        {
          timeout = cfg.timeouts.dpms;
          command = dpmsOff;
          resumeCommand = dpmsOn;
        }
      ]
      ++ optional (cfg.timeouts.suspend > 0) {
        timeout = cfg.timeouts.suspend;
        command = "${pkgs.systemd}/bin/systemctl suspend";
      }
      ++ optional (cfg.timeouts.hibernate > 0) {
        timeout = cfg.timeouts.hibernate;
        command = "${pkgs.systemd}/bin/systemctl hibernate";
      };
    };
  };
}
