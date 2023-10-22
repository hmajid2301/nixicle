{ pkgs, ... }:
let
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
  home.file.".icons" = {
    source = ./icons;
    recursive = true;
  };

  home.packages = [
    volume
    brightness
  ];
}
