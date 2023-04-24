set PATH $HOME/.pyenv/bin $HOME/.poetry/bin $HOME/.local/bin $HOME/go/bin /usr/local/bin $HOME/.cargo/bin $PATH 
set -x GOPATH $HOME/
set -x EDITOR vim
fish_add_path $HOME/.tmux/plugins/t-smart-tmux-session-manager/bin
fish_add_path $HOME/.config/tmux/plugins/t-smart-tmux-session-manager/bin

starship init fish | source
zoxide init fish | source
source ~/.config/fish/extra.fish

fish_vi_key_bindings
bind --mode insert --sets-mode default jk repaint
/usr/local/bin/rtx activate fish | source
