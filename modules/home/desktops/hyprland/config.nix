{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.desktops.hyprland;
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;

      systemd.enable = true;
      systemd.enableXdgAutostart = true;
      xwayland.enable = true;

      settings = {
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
        };

        decoration = {
          rounding = 5;
        };

        misc = let
          FULLSCREEN_ONLY = 2;
        in {
          vrr = FULLSCREEN_ONLY;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          force_default_wallpaper = 0;
        };

        source = ["${config.home.homeDirectory}/.config/hypr/monitors.conf"];

        exec-once =
          [
            "dbus-update-activation-environment --systemd --all"
            "systemctl --user import-environment QT_QPA_PLATFORMTHEME"
            "${pkgs.kanshi}/bin/kanshi"
            "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
            "${pkgs.pyprland}/bin/pypr"
            "${pkgs.clipse}/bin/clipse -listen"
            "${pkgs.solaar}/bin/solaar -w hide"
            "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-indicator"
          ]
          ++ cfg.execOnceExtras;
      };
    };
  };
}
