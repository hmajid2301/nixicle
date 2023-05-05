#!/usr/bin/env fish

abbr --add weather 'curl wttr.in/London'
abbr --add vim nvim
abbr --add n nvim
abbr --add cbr 'git branch --sort=-committerdate | fzf --header "Checkout Recent Branch" --preview "git diff {1} --color=always" | xargs git checkout'
abbr --add gdub 'git fetch -p && git branch -vv | grep ': gone]' | awk '{print }' | xargs git branch -D $argv;'
abbr --add tldrf 'tldr --list | fzf --preview "tldr {1} --color=always" --preview-window=right,70% | xargs tldr'
abbr --add dk=docker kill (docker ps -q)
abbr --add ds=docker stop (docker ps -a -q)
abbr --add drm=docker rm (docker ps -a -q)
