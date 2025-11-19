{delib, ...}:
delib.module {
  name = "desktops-addons-swaylock";

  options.desktops.addons.swaylock = with delib; {
    enable = boolOption false;
    blur = nullableOption lib.types.str "7x5";
    vignette = nullableOption lib.types.str "0.5x0.5";
    binary = nullableOption lib.types.str null;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.desktops.addons.swaylock;
    binary = if cfg.binary != null then cfg.binary else "${pkgs.swaylock-effects}/bin/swaylock";
  in
  mkIf cfg.enable {
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
          command = "${binary} -fF";
        }
        {
          event = "lock";
          command = "${binary} -fF";
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
