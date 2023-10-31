{ lib
, config
, pkgs
, ...
}:

with lib;
let
  cfg = config.modules.wms.sway;
in
{
  options.modules.wms.sway = {
    enable = mkEnableOption "enable sway window manager";
  };

  config = mkIf cfg.enable {
    wayland.windowManager.sway = {
      enable = true;
      package = pkgs.swayfx;
      config = {
        modifier = "Mod4";
        window.titlebar = false;
        terminal = "${config.my.settings.default.terminal}";
        menu = "wofi --show drun";

        input."type:keyboard" = {
          xkb_layout = "gb";
          xkb_options = "ctrl:escape";
        };

        colors = {
          focused = {
            background = "#${config.colorscheme.colors.base07}";
            border = "#${config.colorscheme.colors.base07}";
            childBorder = "#${config.colorscheme.colors.base07}";
            indicator = "#${config.colorscheme.colors.base07}";
            text = "#ffffff";
          };
          unfocused = {
            background = "#${config.colorscheme.colors.base02}";
            border = "#${config.colorscheme.colors.base02}";
            childBorder = "#${config.colorscheme.colors.base02}";
            indicator = "#${config.colorscheme.colors.base02}";
            text = "#ffffff";
          };
        };

        bars = [
          {
            position = "top";
            command = "${pkgs.waybar}/bin/waybar";
          }
        ];

        gaps = {
          inner = 3;
          outer = 5;
        };

        focus = {
          followMouse = true;
        };

        startup = [
          # TODO: try swaync
          { command = "${pkgs.mako}/bin/mako"; }
          { command = "${pkgs.kanshi}/bin/kanshi"; }
          { command = "${pkgs.gammastep}/bin/gammastep-indicator"; }
          { command = "${pkgs.swaybg}/bin/swaybg -i ${config.my.settings.wallpaper} --mode fill"; }
          { command = "sway-audio-idle-inhibit -w"; }
          { command = "${pkgs.flashfocus}/bin/flashfocus"; }
          { command = "${pkgs.autotiling}/bin/autotiling"; }
          {
            command = "exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP=sway XDG_SESSION_DESKTOP=sway";
          }
        ];

        keybindings =
          let inherit (config.wayland.windowManager.sway.config) modifier;
          in lib.mkOptionDefault {
            "${modifier}+b" = "exec ${config.my.settings.default.browser}";
            "${modifier}+a" = "exec ${pkgs.wofi}/bin/wofi --show drun";
            "${modifier}+p" = "exec ${pkgs.rofi}/bin/rofi -show drun -mode drun";
            "${modifier}+q" = "kill";
            "${modifier}+slash" = "workspace back_and_forth";
            "${modifier}+bracketright" = "workspace next";
            "${modifier}+bracketleft" = "workspace prev";
            XF86Launch5 = "swaylock -S";
            XF86Launch4 = "swaylock -S";
            # "${modifier}+backspace" = "swaylock -S";
            "${modifier}+backspace" = "xdg-screensaver lock";

            # Print Screen
            Print = "grimblast --notify copysave area";
            "Shift+Print" = "grimblast --notify copysave active";
            "Control+Print" = "grimblast --notify copysave screen";
            "${modifier}+Print" = "grimblast --notify copy window";
            "ALT+Print" = "grimblast --notify copy area";
            "${modifier}+braceright" = "grimblast --notify --cursor copysave area ~/Pictures/$(date \"+%Y-%m-%d\" T \"%H:%M:%S_no_watermark\").png";
            "${modifier}+braceleft" = "grimblast --notify --cursor copy area";

            # Special Keys
            XF86MonBrightnessUp = "exec brightness --inc";
            XF86MonBrightnessDown = "exec brightness --dec";
            "XF86AudioRaiseVolume" = "exec volume --inc";
            "XF86AudioLowerVolume" = "exec volume --dec";
            XF86AudioMute = "exec volume --toggle";
            XF86AudioMicMute = "exec volume --toggle-mic";
            XF86AudioNext = "playerctl next";
            XF86AudioPrev = "playerctl previous";
            XF86AudioPlay = "playerctl play-pause";
            XF86AudioStop = "playerctl stop";
            "ALT+XF86AudioNext" = "playerctld shift";
            "ALT+XF86AudioPrev" = "playerctld unshift";
            "ALT+XF86AudioPlay" = "systemctl --user restart playerctld";
          };
      };

      extraConfig = ''
        corner_radius 5
        bindswitch --locked --reload lid:on output eDP-1 disable
        bindswitch --locked --reload lid:off output eDP-1 enable
      '';
    };
  };
}
