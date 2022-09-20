#!/bin/sh
source /etc/restic-env
restic -r b2:Majiy00Backup backup -e /home/haseeb/Games -e /home/haseeb/.local/share/Steam -e /home/haseeb/.config/gtk -e /home/haseeb/.cache/ -e /home/haseeb/.steam -e /home/haseeb/.local/share/Trash/   /home/haseeb/res