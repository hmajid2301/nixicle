#!/usr/bin/env bash
#
rofi \
	-show p \
	-modi p:'rofi-power-menu --symbols-font "Symbols Nerd Font Mono"' \
	-font "JetBrains Mono NF 16" \
	-theme Paper \
	-theme-str 'window {width: 8em;} listview {lines: 6;}'
