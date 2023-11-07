{ lib
, config
, pkgs
, ...
}:

with lib;
let
  cfg = config.modules.wms.sway;

  volume = pkgs.writeShellScriptBin "volume" ''
    #!/usr/bin/env bash

    iDIR="$HOME/.icons/"
    pamixer = ${pkgs.pamixer}/bin/pamixer

    # Get Volume
    get_volume() {
    	volume=$(pamixer --get-volume)
    	echo "$volume"
    }

    # Get icons
    get_icon() {
    	current=$(get_volume)
    	if [[ "$current" -eq "0" ]]; then
    		echo "$iDIR/volume-mute.png"
    	elif [[ ("$current" -ge "0") && ("$current" -le "30") ]]; then
    		echo "$iDIR/volume-low.png"
    	elif [[ ("$current" -ge "30") && ("$current" -le "60") ]]; then
    		echo "$iDIR/volume-mid.png"
    	elif [[ ("$current" -ge "60") && ("$current" -le "100") ]]; then
    		echo "$iDIR/volume-high.png"
    	fi
    }

    # Notify
    notify_user() {
    	notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$(get_icon)" "Volume : $(get_volume) %"
    }

    # Increase Volume
    inc_volume() {
    	pamixer -i 5 && notify_user
    }

    # Decrease Volume
    dec_volume() {
    	pamixer -d 5 && notify_user
    }

    # Toggle Mute
    toggle_mute() {
    	if [ "$(pamixer --get-mute)" == "false" ]; then
    		pamixer -m && notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$iDIR/volume-mute.png" "Volume Switched OFF"
    	elif [ "$(pamixer --get-mute)" == "true" ]; then
    		pamixer -u && notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$(get_icon)" "Volume Switched ON"
    	fi
    }

    # Toggle Mic
    toggle_mic() {
    	if [ "$(pamixer --default-source --get-mute)" == "false" ]; then
    		pamixer --default-source -m && notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$iDIR/microphone-mute.png" "Microphone Switched OFF"
    	elif [ "$(pamixer --default-source --get-mute)" == "true" ]; then
    		pamixer -u --default-source u && notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$iDIR/microphone.png" "Microphone Switched ON"
    	fi
    }
    # Get icons
    get_mic_icon() {
    	current=$(pamixer --default-source --get-volume)
    	if [[ "$current" -eq "0" ]]; then
    		echo "$iDIR/microphone.png"
    	elif [[ ("$current" -ge "0") && ("$current" -le "30") ]]; then
    		echo "$iDIR/microphone.png"
    	elif [[ ("$current" -ge "30") && ("$current" -le "60") ]]; then
    		echo "$iDIR/microphone.png"
    	elif [[ ("$current" -ge "60") && ("$current" -le "100") ]]; then
    		echo "$iDIR/microphone.png"
    	fi
    }
    # Notify
    notify_mic_user() {
    	notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$(get_mic_icon)" "Mic-Level : $(pamixer --default-source --get-volume) %"
    }

    # Increase MIC Volume
    inc_mic_volume() {
    	pamixer --default-source -i 5 && notify_mic_user
    }

    # Decrease MIC Volume
    dec_mic_volume() {
    	pamixer --default-source -d 5 && notify_mic_user
    }

    # Execute accordingly
    if [[ "$1" == "--get" ]]; then
    	get_volume
    elif [[ "$1" == "--inc" ]]; then
    	inc_volume
    elif [[ "$1" == "--dec" ]]; then
    	dec_volume
    elif [[ "$1" == "--toggle" ]]; then
    	toggle_mute
    elif [[ "$1" == "--toggle-mic" ]]; then
    	toggle_mic
    elif [[ "$1" == "--get-icon" ]]; then
    	get_icon
    elif [[ "$1" == "--get-mic-icon" ]]; then
    	get_mic_icon
    elif [[ "$1" == "--mic-inc" ]]; then
    	inc_mic_volume
    elif [[ "$1" == "--mic-dec" ]]; then
    	dec_mic_volume
    else
    	get_volume
    fi
  '';

  brightness = pkgs.writeShellScriptBin "brightness" ''
    #!/usr/bin/env bash
    iDIR="$HOME/.icons/"
    brightnessctl = ${pkgs.brightnessctl}/bin/brightnessctl

    # Get brightness
    get_backlight() {
    	echo $(brightnessctl -m | cut -d, -f4)
    }

    # Get icons
    get_icon() {
    	current=$(get_backlight | sed 's/%//')
    	if [ "$current" -le "20" ]; then
    		icon="$iDIR/brightness-20.png"
    	elif [ "$current" -le "40" ]; then
    		icon="$iDIR/brightness-40.png"
    	elif [ "$current" -le "60" ]; then
    		icon="$iDIR/brightness-60.png"
    	elif [ "$current" -le "80" ]; then
    		icon="$iDIR/brightness-80.png"
    	else
    		icon="$iDIR/brightness-100.png"
    	fi
    }

    # Notify
    notify_user() {
    	notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$icon" "Brightness : $current%"
    }

    # Change brightness
    change_backlight() {
    	brightnessctl set "$1" && get_icon && notify_user
    }

    # Execute accordingly
    case "$1" in
    "--get")
    	get_backlight
    	;;
    "--inc")
    	change_backlight "+5%"
    	;;
    "--dec")
    	change_backlight "5%-"
    	;;
    *)
    	get_backlight
    	;;
    esac
  '';
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
          { command = "${pkgs.swaynotificationcenter}/bin/swaync"; }
          { command = "${pkgs.tailscale-systray}/bin/tailscale-systray"; }
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
            Print = "grimblast --notify copysave area";
            "Shift+Print" = "grimblast --notify copysave active";
            "Control+Print" = "grimblast --notify copysave screen";
            "${modifier}+Print" = "grimblast --notify copy window";
            "ALT+Print" = "grimblast --notify copy area";
            "${modifier}+braceright" = "grimblast --notify --cursor copysave area ~/Pictures/$(date \"+%Y-%m-%d\" T \"%H:%M:%S_no_watermark\").png";
            "${modifier}+braceleft" = "grimblast --notify --cursor copy area";

            # Special Keys
            XF86MonBrightnessUp = "exec ${pkgs.brightnessctl}/bin/brightnessctl set +5%";
            XF86MonBrightnessDown = "exec ${brightness}/bin/brightness --dec";
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

      extraConfig = ''
        corner_radius 5
        bindswitch --locked --reload lid:on output eDP-1 disable
        bindswitch --locked --reload lid:off output eDP-1 enable
      '';
    };
  };
}
