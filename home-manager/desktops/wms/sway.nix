{ lib
, config
, pkgs
, inputs
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
    home.packages = [
      inputs.hypr-contrib.packages.${pkgs.system}.grimblast
    ];
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
          { command = "${pkgs.swaynotificationcenter}/bin/swaync"; }
          { command = "${pkgs.tailscale-systray}/bin/tailscale-systray"; }
          { command = "${pkgs.kanshi}/bin/kanshi"; }
          { command = "${pkgs.gammastep}/bin/gammastep-indicator"; }
          { command = "${pkgs.swaybg}/bin/swaybg -i ${config.my.settings.wallpaper} --mode fill"; }
          { command = "sway-audio-idle-inhibit -w"; }
          { command = "${pkgs.flashfocus}/bin/flashfocus"; }
          { command = "${pkgs.autotiling}/bin/autotiling"; }
          # {
          #   command = "exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP=sway XDG_SESSION_DESKTOP=sway";
          # }
        ];

        keybindings =
          let inherit (config.wayland.windowManager.sway.config) modifier;
          in lib.mkOptionDefault {
            "${modifier}+b" = "exec ${config.my.settings.default.browser}";
            "${modifier}+a" = "exec ${pkgs.rofi}/bin/rofi -show drun -mode drun";
            "${modifier}+p" = "exec ${pkgs.wofi}/bin/wofi --show drun";
            "${modifier}+q" = "kill";
            "${modifier}+slash" = "workspace back_and_forth";
            "${modifier}+bracketright" = "workspace next";
            "${modifier}+bracketleft" = "workspace prev";
            XF86Launch5 = "exec ${pkgs.swaylock}/bin/swaylock -fF";
            XF86Launch4 = "exec ${pkgs.swaylock}/bin//swaylock -fF";
            "${modifier}+backspace" = "exec ${pkgs.swaylock}/bin/swaylock -fF";

            # Print Screen
            Print = "exec ${pkgs.grimblast}/bin/grimblast --notify copysave area";
            "Shift+Print" = "exec ${pkgs.grimblast}/bin/grimblast --notify copysave active";
            "Control+Print" = "exec ${pkgs.grimblast}/bin/grimblast --notify copysave screen";
            "${modifier}+Print" = "exec ${pkgs.grimblast}/bin/grimblast --notify copy window";
            "ALT+Print" = "exec ${pkgs.grimblast}/bin/grimblast --notify copy area";
            "${modifier}+braceright" = "$exec ${pkgs.grimblast}/bin/grimblast --notify --cursor copysave area ~/Pictures/$(date \"+%Y-%m-%d\" T \"%H:%M:%S_no_watermark\").png";
            "${modifier}+braceleft" = "exec ${pkgs.grimblast}/bin/grimblast --notify --cursor copy area";

            # Special Keys
            XF86MonBrightnessUp = "exec ${pkgs.brightnessctl}/bin/brightnessctl set +5%";
            XF86MonBrightnessDown = "exec ${pkgs.brightnessctl}/bin/brightnessctl set -5%";
            "XF86AudioRaiseVolume" = "exec ${pkgs.pamixer}/bin/pamixer -i 5";
            "XF86AudioLowerVolume" = "exec ${pkgs.pamixer}/bin/pamixer -d 5";
            XF86AudioMute = "exec ${pkgs.pamixer}/bin/pamixer -t";
            XF86AudioMicMute = "exec ${pkgs.pamixer}/bin/pamixer --default-source -t";
            XF86AudioNext = "playerctl next";
            XF86AudioPrev = "playerctl previous";
            XF86AudioPlay = "playerctl play-pause";
            XF86AudioStop = "playerctl stop";
            "ALT+XF86AudioNext" = "playerctld shift";
            "ALT+XF86AudioPrev" = "playerctld unshift";
            "ALT+XF86AudioPlay" = "systemctl --user restart playerctld";
          };
      };

      extraSessionCommands = lib.mkBefore ''
        export XDG_CURRENT_DESKTOP=sway XDG_SESSION_TYPE=wayland XDG_SESSION_DESKTOP=sway
      '';

      extraConfig = ''
        corner_radius 5
        bindswitch --locked --reload lid:on output eDP-1 disable
        bindswitch --locked --reload lid:off output eDP-1 enable

        # Do the following command in a terminal emulator when you need the virtual output:
        # swaymsg create_output

        output HEADLESS-1 resolution 1920x1080 position 0,1080
        output HEADLESS-1 bg "#220900" solid_color
        workspace 0 output HEADLESS-1
        bindsym Mod4+0 workspace number 0
        bindsym Mod4+Shift+0 move container to workspace number 0
        include ~/.config/sway/outputs
      '';
    };
  };
}
