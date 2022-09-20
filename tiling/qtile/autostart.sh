#!/bin/sh

nitrogen --restore
picom -f &
udiskie &
redshift &
rofi-polkit-agent &
autorandr default &
flameshot &
solaar &
docker run --rm --publish 5000:5000 --detach --name whoogle-search benbusby/whoogle-search:latest &