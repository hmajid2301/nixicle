#!/usr/bin/env fish

abbr --add weather 'curl wttr.in/London'
abbr --add vim nvim
abbr --add n nvim
abbr --add gdub 'git fetch -p && git branch -vv | grep ': gone]' | awk '{print }' | xargs git branch -D $argv;'
abbr --add tldrf 'tldr --list | fzf --preview "tldr {1} --color=always" --preview-window=right,70% | xargs tldr'
