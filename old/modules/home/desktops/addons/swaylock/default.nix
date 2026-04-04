{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.desktops.addons.swaylock;
in
{
  options.desktops.addons.swaylock = {
    enable = mkEnableOption "Enable swaylock lock management";
    blur = mkOpt (types.nullOr types.str) "7x5" "radius x times blur the image.";
    vignette = mkOpt (types.nullOr types.str) "0.5x0.5" "base:factor apply vignette effect.";
    binary =
      mkOpt (types.nullOr types.str) "${pkgs.swaylock-effects}/bin/swaylock"
        "Location of the binary to use for swaylock.";
  };

  config = mkIf cfg.enable {
    programs.swaylock = {
      enable = true;
      package = pkgs.swaylock-effects;
      settings = {
        show-failed-attempts = true;
        screenshots = true;
        clock = true;

        indicator = true;
        indicator-radius = 350;
        indicator-thickness = 5;

        effect-blur = cfg.blur;
        effect-vignette = cfg.vignette;
        fade-in = 0.2;

        font = "MonoLisa Nerd Font";
      };
    };

    services.swayidle = {
      enable = true;
      systemdTarget = "hyprland-session.target";
      events = [
        {
          event = "before-sleep";
          command = "${cfg.binary} -fF";
        }
        {
          event = "lock";
          command = "${cfg.binary} -fF";
        }
      ];
      timeouts = [
        {
          timeout = 600;
          command = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms off";
          resumeCommand = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms on";
        }
        {
          timeout = 610;
          command = "${pkgs.systemd}/bin/loginctl lock-session";
        }
      ];
    };
  };
}
