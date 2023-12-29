{pkgs, ...}: let
  volume = pkgs.writeShellScriptBin "volume" ''
    #!/usr/bin/env bash

    # Get Volume
    get_volume() {
    	volume=$(pamixer --get-volume)
    	echo "$volume"
    }

    # Notify
    notify_user() {
    	notify-send -h string:x-canonical-private-synchronous:sys-notify -u low  "Volume : $(get_volume) %"
    }

    # Increase Volume
    inc_volume() {
    	pamixer -u
    	pamixer -i 5 && notify_user
    }

    # Decrease Volume
    dec_volume() {
    	pamixer -d 5 && notify_user
    }

    # Toggle Mute
    toggle_mute() {
    	if [ "$(pamixer --get-mute)" == "false" ]; then
    		pamixer -m && notify-send -h string:x-canonical-private-synchronous:sys-notify -u low "Volume Switched OFF"
    	elif [ "$(pamixer --get-mute)" == "true" ]; then
    		pamixer -u && notify-send -h string:x-canonical-private-synchronous:sys-notify -u low  "Volume Switched ON"
    	fi
    }

    # Toggle Mic
    toggle_mic() {
    	if [ "$(pamixer --default-source --get-mute)" == "false" ]; then
    		pamixer --default-source -m && notify-send -h string:x-canonical-private-synchronous:sys-notify -u low  "Microphone Switched OFF"
    	elif [ "$(pamixer --default-source --get-mute)" == "true" ]; then
    		pamixer -u --default-source u && notify-send -h string:x-canonical-private-synchronous:sys-notify -u low  "Microphone Switched ON"
    	fi
    }

    # Notify
    notify_mic_user() {
    	notify-send -h string:x-canonical-private-synchronous:sys-notify -u low "Mic-Level : $(pamixer --default-source --get-volume) %"
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
    brightnessctl = ${pkgs.brightnessctl}/bin/brightnessctl

    # Get brightness
    get_backlight() {
    	echo $(brightnessctl -m | cut -d, -f4)
    }

    # Notify
    notify_user() {
    	notify-send -h string:x-canonical-private-synchronous:sys-notify -u low "Brightness : $current%"
    }

    # Change brightness
    change_backlight() {
    	brightnessctl set "$1" && notify_user
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
in {
  home.packages = [
    volume
    brightness
    pkgs.libnotify
  ];
}
