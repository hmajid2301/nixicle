{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: {
  imports = [
    ./keybindings.nix
    ./windowrules.nix
  ];

  wayland.windowManager.hyprland = {
    enable = config.modules.wms.hyprland.enable;
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
        active_border_color = "0xff${config.colorscheme.colors.base07}";
        inactive_border_color = "0xff${config.colorscheme.colors.base02}";
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

      env = [
        "WLR_DRM_DEVICES,/dev/dri/card1:/dev/dri/card0"
      ];

      exec_once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "${pkgs.swaynotificationcenter}/bin/swaync"
        "${pkgs.kanshi}/bin/kanshi"
        "${pkgs.nur.repos."999eagle".swayaudioidleinhibit}/bin/sway-audio-idle-inhibit -w"
        "${pkgs.waybar}/bin/waybar"
        "${pkgs.gammastep}/bin/gammastep"
        "${pkgs.swaybg}/bin/swaybg -i ${config.my.settings.wallpaper} --mode fill"
        "${pkgs.trayscale}/bin/trayscale --hide-window"
        "mullvad-gui"
        "solaar -w hide"
        "blueman-applet"
      ];
    };
  };
}
