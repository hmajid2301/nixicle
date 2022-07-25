#!/bin/bash

# You can call this script like this:
# $./volume.sh up
# $./volume.sh down
# $./volume.sh mute
# $./volume.sh mtoggle

device='default'    #audio device
interval='5'        #Percentage by which to update the volume
timeout='1'         #Notification timeout in seconds
bar_char="■"        #Character to use for the volume bar
padding="    "      #Space to pad out the bar at the left of the notification

# The dunstify timeout is in milliseconds, so multiply our seconds setting by 1000
notify_timeout=$((timeout*1000))

#Icon settings
#Base for all icons, or you can specify the full path to each
icon_base="/usr/share/icons/Adwaita/32x32/status"
# Icon for when volume is changed
icon_audio_vol="$icon_base/audio-volume-high-symbolic.symbolic.png"
# Icon for when volume is muted
icon_audio_muted="$icon_base/audio-volume-muted-symbolic.symbolic.png"
# Icon when mic is on
icon_capture_on="$icon_base/microphone-sensitivity-high-symbolic.symbolic.png"
# Icon when mic is off
icon_capture_off="$icon_base/microphone-disabled-symbolic.symbolic.png"
# Icon for when the mic status is unknown
icon_capture_unk="$icon_base/microphone-hardware-disabled-symbolic.symbolic.png"

function get_volume {
    amixer get Master | grep '%' | head -n 1 | cut -d '[' -f 2 | cut -d '%' -f 1
}

function is_mute {
    amixer get Master | grep '%' | grep -oE '[^ ]+$' | grep off > /dev/null
}

function send_notification {
    volume=$(get_volume)
    bar=$(seq -s "$bar_char" $((((volume / 5)+1))) | sed 's/[0-9]//g')
    # Send the notification
    dunstify -i "$icon_audio_vol" -t $notify_timeout -r 2593 -u normal "$padding$bar"

}

function get_mic_toggle {
    # Send the notification for the current micrphone status
    # Get the mic status
    micstatus=$(amixer get Capture|grep '%' | grep -oE '[^ ]+$')
    # The capture will probably have more than one channel, so we need to get the number of channels
    channels=$(wc -l <<< "$micstatus")
    # Now we are going to count the number that are "on"
    num_on=$(grep -o 'on' <<< "$micstatus"|wc -l)
    # And count the number that are "off"
    num_off=$(grep -o 'off' <<< "$micstatus"|wc -l)
    # If the number of on match the number of channels, weknow the mic is on
    if [ "$channels" -eq "$num_on" ];then
        dunstify -t $notify_timeout -i "$icon_capture_on" -r 2593 -u normal "${padding}On"
    # If the number of off match the number of channels, we know the mic is off
    elif [ "$channels" -eq "$num_off" ];then
        dunstify -t $notify_timeout -i "$icon_capture_off" -r 2593 -u normal "${padding}Off"
    # If the number of on and off don't match the number of channels, we don't really know the status
    else
        dunstify -t $notify_timeout -i "$icon_capture_unk" -r 2593 -u normal "${padding}Unknown"
    fi
}

case $1 in
    up)
        # Set the volume on (if it was muted)
        amixer -D "$device" set Master on > /dev/null
        # Up the volume (+ $interval%)
        amixer -D "$device" sset Master $interval%+ > /dev/null
        send_notification
	;;
    down)
        amixer -D "$device" set Master on > /dev/null
        amixer -D "$device" sset Master $interval%- > /dev/null
        send_notification
	;;
    mute)
    	# Toggle mute
        amixer -D "$device" set Master 1+ toggle > /dev/null
        if is_mute ; then
            dunstify -t $notify_timeout -i "$icon_audio_muted" -r 2593 -u normal "Mute"
        else
            send_notification
        fi
	;;
    mtoggle)
    	# Toggle microphone mute
        amixer set Capture toggle > /dev/null
        get_mic_toggle
	;;
esac