#!/usr/bin/env bash

ID1=$(awk '/ Built-in Audio Analog Stereo/ {sub(/.$/,"",$2); print $2 }' <(${pkgs.wireplumber}/bin/wpctl status) | head -n 1)
ID2=$(awk '/ G560 Gaming Speaker Analog Stereo/ {sub(/.$/,"",$2); print $2 }' <(${pkgs.wireplumber}/bin/wpctl status) | sed -n 2p)

HEAD=$(awk '/ Built-in Audio Analog Stereo/ { print $2 }' <(${pkgs.wireplumber}/bin/wpctl status | grep "*") | sed -n 2p)
SPEAK=$(awk '/ G560 Gaming Speaker Analog Stereo/ { print $2 }' <(${pkgs.wireplumber}/bin/wpctl status | grep "*") | head -n 1)

if [[ $HEAD = "*" ]]; then
  ${pkgs.wireplumber}/bin/wpctl set-default $ID2
elif [[ $SPEAK = "*" ]]; then
  ${pkgs.wireplumber}/bin/wpctl set-default $ID1
fi
exit 0
