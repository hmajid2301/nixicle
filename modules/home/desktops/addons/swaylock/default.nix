{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle; let
  inherit (config.colorScheme) palette;
  cfg = config.desktops.addons.swaylock;
in {
  options.desktops.addons.swaylock = {
    enable = mkEnableOption "Enable swaylock lock management";
    blur = mkOpt (types.nullOr types.str) "7x5" "radius x times blur the image.";
    vignette = mkOpt (types.nullOr types.str) "0.5x0.5" "base:factor apply vignette effect.";
    binary = mkOpt (types.nullOr types.str) "${pkgs.swaylock-effects}/bin/swaylock" "Location of the binary to use for swaylock.";
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
        ring-color = "${palette.base02}";
        inside-wrong-color = "${palette.base08}";
        ring-wrong-color = "${palette.base08}";
        key-hl-color = "${palette.base0B}";
        bs-hl-color = "${palette.base08}";
        ring-ver-color = "${palette.base09}";
        inside-ver-color = "${palette.base09}";
        inside-color = "${palette.base01}";
        text-color = "${palette.base07}";
        text-clear-color = "${palette.base01}";
        text-ver-color = "${palette.base01}";
        text-wrong-color = "${palette.base01}";
        text-caps-lock-color = "${palette.base07}";
        inside-clear-color = "${palette.base0C}";
        ring-clear-color = "${palette.base0C}";
        inside-caps-lock-color = "${palette.base09}";
        ring-caps-lock-color = "${palette.base02}";
        separator-color = "${palette.base02}";
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
