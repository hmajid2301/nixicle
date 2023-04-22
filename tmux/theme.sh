#!/usr/bin/env bash
#

set -e

main() {
  bootstrapColors
  bootstrapStatusLine
  styleWindows
  stylePaneBorder
  styleMode

  statusLeft
  statusRight
}

bootstrapStatusLine() {
  tmux set-option -g status on
  tmux set-option -g status-style "fg=${white},bg=default"
  tmux set-option -g status-justify left
  tmux set-option -g status-interval 5
}

styleWindows() {
  sep_style="#[bg=default,fg=${comment},nobold,noitalics,nounderscore]"
  tmux setw -g window-status-format "#[fg=${comment},bg=default] #I #W "
  tmux setw -g window-status-current-format "${sep_style}${left_bubble}#[bg=${comment},fg=${dark_gray},bold] #I #W ${sep_style}${right_bubble}"
}

stylePaneBorder() {
  tmux set-option -g pane-border-style "fg=${gray},bg=default"
  tmux set-option -g pane-active-border-style "fg=${purple},bg=default"
}

styleMode() {
  tmux setw -g mode-style "fg=${yellow},bg=default,bold"
}

statusLeft() {
  tmux set-option -g status-left ""
}

statusRight() {
  tmux set-option -g status-right ""
  tmux set-option -ag status-right "#[fg=${purple},bg=default,nobold,noitalics,nounderscore]${left_bubble}#[fg=${dark_gray},bg=${purple},bold]  %a %e %b %H:%M"
  tmux set-option -ag status-right " #[fg=${gray},bg=${purple},nobold,noitalics,nounderscore]${left_bubble}#[bg=${gray}]#[fg=${purple},bg=${gray},bold]  #S "
}

bootstrapColors() {
  white="#f8f8f2"
  gray="#44475a"
  dark_gray="#282a36"
  purple="#bd93f9"
  comment="#6272a4"
  cyan="#8be9fd"
  green="#50fa7b"
  orange="#ffb86c"
  red="#ff5555"
  pink="#ff79c6"
  yellow="#f1fa8c"

  left_bubble=""
  right_bubble=""
  right_sep=""
  left_sep=""
}

main
