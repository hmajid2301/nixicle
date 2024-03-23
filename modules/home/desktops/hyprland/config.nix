{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.desktops.hyprland;
  inherit (config.colorScheme) palette;
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      package = pkgs.hyprland;

      reloadConfig = true;
      systemdIntegration = true;
      recommendedEnvironment = true;
      xwayland.enable = true;

      config = {
        input = {
          kb_layout = "gb";
          touchpad = {
            disable_while_typing = false;
          };
        };

        general = {
          gaps_in = 3;
          gaps_out = 5;
          border_size = 3;
          active_border_color = "0xff${palette.base07}";
          inactive_border_color = "0xff${palette.base02}";
        };

        decoration = {
          rounding = 5;
        };

        misc = let
          FULLSCREEN_ONLY = 2;
        in {
          vrr = 2;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          force_default_wallpaper = 0;
          variable_framerate = true;
          variable_refresh = FULLSCREEN_ONLY;
          disable_autoreload = true;
        };

        exec_once = [
          "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
          "${pkgs.swaynotificationcenter}/bin/swaync"
          "${pkgs.kanshi}/bin/kanshi"
          "${pkgs.waybar}/bin/waybar"
          #"${pkgs.swaybg}/bin/swaybg -i ${pkgs.nixicle.wallpaper}/share/wallpapers/Kurzgesagt-Galaxy_3.png --mode fill"
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
          "solaar -w hide"
        ];
      };
    };
  };
}
